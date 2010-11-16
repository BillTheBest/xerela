/*
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * The Original Code is Ziptie Client Framework.
 * 
 * The Initial Developer of the Original Code is AlterPoint.
 * Portions created by AlterPoint are Copyright (C) 2006,
 * AlterPoint, Inc. All Rights Reserved.
 * 
 * Contributor(s):
 */

package org.xerela.server.discovery;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.xml.ws.soap.SOAPFaultException;

import org.apache.log4j.Logger;
import org.snmp4j.AbstractTarget;
import org.xerela.addressing.IPAddress;
import org.xerela.common.StringElf;
import org.xerela.credentials.CredentialSet;
import org.xerela.discovery.DiscoveryEvent;
import org.xerela.discovery.DiscoveryEventParser;
import org.xerela.discovery.DiscoveryHost;
import org.xerela.discovery.IInventoryCallbacks;
import org.xerela.discovery.XdpEntry;
import org.xerela.exception.PersistenceException;
import org.xerela.net.adapters.AdapterService;
import org.xerela.net.client.ConnectionPath;
import org.xerela.net.client.DiscoveryParams;
import org.xerela.net.client.Telemetry;
import org.xerela.net.snmp.SnmpException;
import org.xerela.net.snmp.SnmpManager;
import org.xerela.protocols.Protocol;
import org.xerela.protocols.ProtocolNames;
import org.xerela.protocols.ProtocolSet;
import org.xerela.provider.credentials.ICredentialsProvider;
import org.xerela.provider.devices.ZDeviceCore;
import org.xerela.security.PermissionDeniedException;
import org.xerela.server.discovery.internal.DiscoveryActivator;
import org.xerela.server.job.AdapterEndpointElf;
import org.xerela.server.job.AdapterException;
import org.xerela.server.job.PerlErrorParserElf;
import org.xerela.server.job.AdapterException.ErrorCode;
import org.xerela.server.job.backup.ConnectionPathElf;
import org.xerela.zap.jta.TransactionElf;

/**
 * @author rkruse
 */
public class DiscoveryInventoryCallback implements IInventoryCallbacks
{
    private static Logger LOGGER = Logger.getLogger(DiscoveryInventoryCallback.class);
    private static String SYS_DESCR = "1.3.6.1.2.1.1.1.0";
    private static String SYS_OID = "1.3.6.1.2.1.1.2.0";
    private static String SYS_NAME = "1.3.6.1.2.1.1.5.0";

    /**
     * Default constructor
     * 
     */
    public DiscoveryInventoryCallback()
    {
    }

    /** {@inheritDoc} */
    public IPAddress getPreferredIpAddress(IPAddress ipAddress) throws UnknownHostException
    {
        boolean ownTransaction = TransactionElf.beginOrJoinTransaction();
        try
        {
            ZDeviceCore deviceByInterfaceIp = DiscoveryActivator.getDeviceProvider().getDeviceByInterfaceIp(ipAddress.getIPAddress(), null);
            if (deviceByInterfaceIp == null)
            {
                throw new UnknownHostException();
            }
            else
            {
                return new IPAddress(deviceByInterfaceIp.getIpAddress());
            }
        }
        finally
        {
            if (ownTransaction)
            {
                TransactionElf.commit();
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public DiscoveryEvent discoveryMethod(DiscoveryHost discoveryHost, boolean runTelemetry)
    {
        /**
         * TODO: rkruse - this should be done in an extension to the AbstractAdapterTask once the DiscoveryEngine uses the core dispatcher.
         */
        File telemetryFile = null;
        IPAddress ip = discoveryHost.getIpAddress();
        TransactionElf.beginOrJoinTransaction();
        ZDeviceCore device = getDevice(ip);
        ProtocolSet protocols = getProtocols(ip, device);
        List<CredentialSet> credentials = getCredentials(ip);

        DiscoveryEvent event = new DiscoveryEvent(ip);
        populateAdapterId(device, discoveryHost, credentials, protocols, event);
        if (event.getAdapterId() == null || !runTelemetry)
        {
            return event;
        }

        int credCounter = 0;
        while (credCounter < credentials.size())
        {
            try
            {
                CredentialSet credentialSet = credentials.get(credCounter);
                LOGGER.debug("Executing telemetry operation on " + ip + " with the credentials '" + credentialSet.getName() + "'.");
                ConnectionPath connectionPath = ConnectionPathElf.generateSoapConnectionPath(ip.getIPAddress(), protocols, credentialSet);
                DiscoveryParams discoveryParams = new DiscoveryParams();
                discoveryParams.setCalculateAdminIp(discoveryHost.isCalculateAdminIp() && device == null);
                String telemetry = AdapterEndpointElf.getEndpoint(Telemetry.class, event.getAdapterId()).telemetry(connectionPath, discoveryParams);
                String filename = (ip + "_telemetry.xml").replaceAll(":+", "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
                telemetryFile = StringElf.stringToTempFile(filename, telemetry);

                DiscoveryEventParser discoveryEventParser = new DiscoveryEventParser(new FileInputStream(telemetryFile));
                discoveryEventParser.setDiscoveryEvent(event);
                event = discoveryEventParser.parseEvent();
                return event;
            }
            catch (IOException e)
            {
                throw new RuntimeException("Discovery method failed writing the telemetry temp file", e);
            }
            catch (SOAPFaultException e)
            {
                String message = PerlErrorParserElf.getMessage(e);

                AdapterException adapterException = PerlErrorParserElf.parse(message);
                if (adapterException != null
                        && (adapterException.getErrorCode().equals(ErrorCode.INVALID_CREDENTIALS) || adapterException.getErrorCode()
                                                                                                                     .equals(ErrorCode.SNMP_ERROR)))
                {
                    credCounter++;
                    LOGGER.debug("Discovery failed against " + ip + " due to invalid credentials.  Trying next available set of credentials.");
                    if (credCounter >= credentials.size())
                    {
                        LOGGER.warn("Unable to discover neighbor data for " + ip + " due to invalid credentials.");
                    }
                }
                else
                {
                    return event;
                }
            }
            finally
            {
                if (telemetryFile != null && telemetryFile.exists())
                {
                    telemetryFile.delete();
                }
            }
        }
        return event;
    }

    /**
     * Figure out the best adapter to use
     * @param device 
     * @param discoveryHost
     * @param credentials
     * @param protocols
     * @return
     */
    private void populateAdapterId(ZDeviceCore device, DiscoveryHost discoveryHost, List<CredentialSet> credentials,
                                   ProtocolSet protocols, DiscoveryEvent event)
    {
        if (device != null)
        {
            event.setDeviceId(device.getDeviceId());
            event.setAdapterId(device.getAdapterId());
        }
        else
        {
            if (discoveryHost.isFromXdp())
            {
                String adapterId = DiscoveryActivator.getAdapterService().getAdapterId(discoveryHost.getXdpEntry());
                if (adapterId != null)
                {
                    event.setAdapterId(adapterId);
                    XdpEntry xdpEntry = discoveryHost.getXdpEntry();
                    event.setSysName(xdpEntry.getSysName());
                    event.setSysDescr(xdpEntry.getSysDescr());
                    event.setSysOID(xdpEntry.getSysOid());
                    event.setGoodEvent(true);
                }
            }

            if (event.getAdapterId() == null)
            {
                getAdapterIdViaSnmp(event, discoveryHost, credentials, protocols);
            }
        }
    }

    /**
     * Use SNMP to get system level information and pass that through to the adapter service to match it to an adapter.
     * @param event 
     * @param discoveryHost
     * @param credentials
     * @param protocols
     * @return null if the device doesn't respond to SNMP, returns the generic adapter if it responds but doesn't match another adapter
     */
    private void getAdapterIdViaSnmp(DiscoveryEvent event, DiscoveryHost discoveryHost, List<CredentialSet> credentialSets, ProtocolSet protocols)
    {
        Protocol snmpProtocol = null;
        for (Protocol protocol : protocols.getProtocols())
        {
            if (protocol.getName().equals(ProtocolNames.SNMP.name()))
            {
                snmpProtocol = protocol;
            }
        }

        List<String> oids = new ArrayList<String>();
        oids.add(SYS_DESCR);
        oids.add(SYS_OID);
        oids.add(SYS_NAME);

        if (snmpProtocol != null)
        {
            SnmpManager snmpManager = SnmpManager.getInstance();
            for (CredentialSet credentials : credentialSets)
            {
                AbstractTarget target = snmpManager.buildTarget(discoveryHost.getIpAddress(), snmpProtocol, credentials);
                try
                {
                    Map<String, String> result = snmpManager.snmpGet(oids, target);
                    event.setSysName(result.get(SYS_NAME));
                    event.setSysOID(result.get(SYS_OID));
                    event.setSysDescr(result.get(SYS_DESCR));
                    event.setGoodEvent(true);

                    String adapterId = DiscoveryActivator.getAdapterService().getAdapterId(event);
                    event.setAdapterId((adapterId == null) ? AdapterService.GENERIC_ADAPTER_ID : adapterId);
                    return;
                }
                catch (SnmpException e)
                {
                    LOGGER.debug("The host " + discoveryHost.getIpAddress() + " is not responding to SNMP using the '" + credentials.getName()
                            + "' credentials.");
                }
            }
        }
    }

    /**
     * Get a device by the IP
     * @param ip
     * @return
     */
    private ZDeviceCore getDevice(IPAddress ip)
    {
        boolean ownTransaction = TransactionElf.beginOrJoinTransaction();
        try
        {
            return DiscoveryActivator.getDeviceProvider().getDevice(ip.getIPAddress(), null);
        }
        finally
        {
            if (ownTransaction)
            {
                TransactionElf.commit();
            }
        }
    }

    private ProtocolSet getProtocols(IPAddress ipAddress, ZDeviceCore device)
    {
        boolean ownTransaction = TransactionElf.beginOrJoinTransaction();

        try
        {
            ICredentialsProvider credProvider = DiscoveryActivator.getCredentialsProvider();
            String deviceId = (device == null) ? null : Integer.toString(device.getDeviceId());
            return credProvider.getAllEnabledProtocols(ipAddress.getIPAddress(), deviceId);
        }
        catch (PersistenceException e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
            if (ownTransaction)
            {
                TransactionElf.commit();
            }
        }

    }

    /**
     * Get the credentials associated with the ip
     * 
     * @param ipAddress
     * @return
     * @throws PersistenceException 
     * @throws PermissionDeniedException 
     */
    private List<CredentialSet> getCredentials(IPAddress ipAddress)
    {
        boolean ownTransaction = TransactionElf.beginOrJoinTransaction();

        try
        {
            ICredentialsProvider credProvider = DiscoveryActivator.getCredentialsProvider();
            return credProvider.getCredentialSetsByIpAddress(ipAddress.toString());
        }
        catch (PermissionDeniedException e)
        {
            throw new RuntimeException(e);
        }
        catch (PersistenceException e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
            if (ownTransaction)
            {
                TransactionElf.commit();
            }
        }
    }
}
