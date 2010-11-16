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

/* Alterpoint, Inc.
 *
 * The contents of this source code are proprietary and confidential
 * All code, patterns, and comments are Copyright Alterpoint, Inc. 2003-2006
 *
 *   $Author: rkruse $
 *     $Date: 2008/08/07 18:26:15 $
 * $Revision: 1.8 $
 *   $Source: /usr/local/cvsroot/org.xerela.net/src/org/xerela/discovery/ArpEntry.java,v $e
 */

package org.xerela.discovery;

import org.xerela.addressing.IPAddress;
import org.xerela.addressing.MACAddress;

/**
 * Represents a typical ARP cache entry on a forwarding network device.
 * 
 * Here is an example entry<br>
 * 
 * <pre>
 *    Protocol  Address          Age (min)  Hardware Addr   Type   Interface
 *    Internet  10.100.4.6              4   00e0.1659.7f81  ARPA   Ethernet0/0
 * </pre>
 * 
 * @author rkruse
 */
@SuppressWarnings("nls")
public class ArpEntry extends TelemetryObject
{
    private IPAddress ipAddress;
    private MACAddress macAddress;
    private String interfaceName = "";

    /**
     * default constructor, only here to satisfy hibernate.
     */
    public ArpEntry()
    {
    }

    /**
     * Set up an entry with minimal information
     * 
     * @param ipAddress the ipAddress of the entry
     * @param macAddress the mac of the entry
     */
    public ArpEntry(IPAddress ipAddress, MACAddress macAddress)
    {
        this.ipAddress = ipAddress;
        this.macAddress = macAddress;
    }

    /**
     * This will be something like <i>ethernet0/0</i>
     * 
     * @return the interfaceName
     */
    public String getInterfaceName()
    {
        return interfaceName;
    }

    /**
     * This will be something like <i>ethernet0/0</i>
     * 
     * @param interfaceName the interfaceName to set
     */
    public void setInterfaceName(String interfaceName)
    {
        if (interfaceName != null)
        {
            this.interfaceName = interfaceName;
        }
    }

    /**
     * @return the ipAddress
     */
    public IPAddress getIpAddress()
    {
        return ipAddress;
    }

    /**
     * @param ipAddress the ipAddress to set
     */
    public void setIpAddress(IPAddress ipAddress)
    {
        this.ipAddress = ipAddress;
    }

    /**
     * @return the macAddress
     */
    public MACAddress getMacAddress()
    {
        return macAddress;
    }

    /**
     * @param macAddress the macAddress to set
     */
    public void setMacAddress(MACAddress macAddress)
    {
        this.macAddress = macAddress;
    }

    /** {@inheritDoc} */
    @Override
    public int hashCode()
    {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((ipAddress == null) ? 0 : ipAddress.hashCode());
        result = prime * result + ((macAddress == null) ? 0 : macAddress.hashCode());
        return result;
    }

    /** {@inheritDoc} */
    @Override
    public boolean equals(Object obj)
    {
        if (this == obj)
        {
            return true;
        }
        if (obj == null)
        {
            return false;
        }
        if (getClass() != obj.getClass())
        {
            return false;
        }
        final ArpEntry other = (ArpEntry) obj;
        if (ipAddress == null)
        {
            if (other.ipAddress != null)
            {
                return false;
            }
        }
        else if (!ipAddress.equals(other.ipAddress))
        {
            return false;
        }

        if (macAddress == null)
        {
            if (other.macAddress != null)
            {
                return false;
            }
        }
        else if (!macAddress.equals(other.macAddress))
        {
            return false;
        }
        return true;
    }

    /** {@inheritDoc} */
    @Override
    public String toString()
    {
        return ipAddress + "\t" + macAddress + "\t" + interfaceName;
    }

}
