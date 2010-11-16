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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.net.SocketException;
import java.nio.channels.DatagramChannel;
import java.nio.channels.SelectionKey;

import org.xerela.nio.common.SystemLogger;
import org.xerela.nio.common.ThreadUtils;
import org.xerela.nio.nioagent.ChannelSelectorImpl;
import org.xerela.nio.nioagent.WrapperException;
import org.xerela.nio.nioagent.Interfaces.ChannelSelector;
import org.xerela.nio.nioagent.Interfaces.KeyAttachment;
import org.xerela.nio.nioagent.datagram.ChannelUtils;
import org.xerela.nio.nioagent.datagram.tftp.TftpServer;
import org.xerela.nio.nioagent.datagram.tftp.server.BasicTftpServer;


public class Perf2Server implements SystemLogger.Injector
{
    // -- static fields
    private static volatile boolean stillRunning = true;

    // -- public methods
    public static void main(String[] args)
    {
        ChannelSelector selector = ChannelSelectorImpl.getInstance(logger);
        TftpServer server = BasicTftpServer.getInstance(logger);
        try
        {
            server.start();
            logger.debug("Perf2 server running.");
            startKillServer(selector);
            Process clientProc = startPerf2Client(Runtime.getRuntime(), args[0], args[1]);
            startClientReader(clientProc.getInputStream(), clientProc.getErrorStream());
            while (stillRunning)
            {
                ThreadUtils.sleep(500, logger);
            }
        }
        catch (RuntimeException e)
        {
            logger.error("Failure running perf2 server.", e);
            throw e;
        }
        finally
        {
            server.stop();
            selector.stop();
            logger.debug("Server stopped.");
        }
    }

    private static void startKillServer(ChannelSelector selector)
    {
        DatagramChannel chan = ChannelUtils.openInit(logger);
        bindSocket(chan.socket(), new InetSocketAddress(50000));
        selector.register(chan, SelectionKey.OP_READ, att());
    }

    private static void bindSocket(DatagramSocket socket, SocketAddress addr)
    {
        try
        {
            socket.bind(addr);
        }
        catch (SocketException e)
        {
            logger.error("Failed to bind socket.");
            throw new WrapperException(e);
        }
    }

    private static KeyAttachment att()
    {
        return new KeyAttachment()
        {
            public void control(SelectionKey key)
            {
                logger.debug("Receive request to stop the server.");
                stillRunning = false;
                key.interestOps(0);
            }
        };
    }

    private static Process startPerf2Client(Runtime runtime, String numTransfers, String repeats)
    {
        try
        {
            return runtime.exec("perf2client.bat " + numTransfers + " " + repeats);
        }
        catch (IOException e)
        {
            logger.error("Failed to execute Perf2Client. ", e);
            throw new WrapperException(e);
        }
    }

    private static void startClientReader(InputStream clientOut, InputStream clientErr)
    {
        Thread clientReader = new Thread(clientReaderRunnable(clientOut, clientErr), "client reader");
        clientReader.setDaemon(true);
        clientReader.start();
    }

    private static Runnable clientReaderRunnable(final InputStream clientOut, final InputStream clientErr)
    {
        return new Runnable()
        {
            public void run()
            {
                while (true)
                {
                    printFromStream(clientOut);
                    printFromStream(clientErr);
                }
            }
        };
    }

    private static void printFromStream(InputStream in)
    {
        BufferedReader reader = new BufferedReader(new InputStreamReader(in));
        while (ready(reader))
        {
            logger.debug("CLIENT: " + readLine(reader));
        }

    }

    private static boolean ready(BufferedReader reader)
    {
        try
        {
            return reader.ready();
        }
        catch (IOException e)
        {
            logger.error("Failed to check how many bytes are available from input stream.");
            throw new WrapperException(e);
        }
    }

    private static String readLine(BufferedReader reader)
    {
        try
        {
            return reader.readLine();
        }
        catch (IOException e)
        {
            logger.error("Failed to read from input stream.");
            throw new WrapperException(e);
        }
    }

}
