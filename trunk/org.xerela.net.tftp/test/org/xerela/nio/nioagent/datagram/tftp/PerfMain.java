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

package org.xerela.nio.nioagent.datagram.tftp;

import org.xerela.nio.common.SystemLogger;
import org.xerela.nio.nioagent.ChannelSelectorImpl;
import org.xerela.nio.nioagent.datagram.tftp.TftpServer;
import org.xerela.nio.nioagent.datagram.tftp.server.BasicTftpServer;


public class PerfMain implements SystemLogger.Injector
{
    // -- static fields
    private static final byte[] testPattern = new byte[] { 'c', 'h', 'r', 'i', 's', '_', 'l', 'e', 'a', 'k', '_' };
    private static final int numPatternRepetitions = 25000;

    // -- public methods
    public static void main(String[] args)
    {
        TftpServer server = BasicTftpServer.getInstance(logger);
        try
        {
            int numClients = Integer.parseInt(args[0]);
            logger.debug("Running perf test with " + numClients + " transfers.");
            FileGenerator gen = new FileGenerator("var/tftp", "perftest.txt", testPattern, numPatternRepetitions);
            server.start();
            ClientRunner clientRunner = new ClientRunner(numClients, "perftest.txt", gen);
            clientRunner.run();
        }
        catch (RuntimeException e)
        {
            logger.error("Faulure running PerfMain.", e);
            throw e;
        }
        finally
        {
            server.stop();
            ChannelSelectorImpl.getInstance(logger).stop();
        }
    }

}
