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

import java.nio.channels.Selector;

import org.xerela.nio.common.SystemLogger;
import org.xerela.nio.common.ThreadUtils;
import org.xerela.nio.nioagent.ChannelSelectorAccessor;
import org.xerela.nio.nioagent.ChannelSelectorImpl;
import org.xerela.nio.nioagent.WrapperException;
import org.xerela.nio.nioagent.Interfaces.ChannelSelector;
import org.xerela.nio.nioagent.datagram.tftp.TftpServer;
import org.xerela.nio.nioagent.datagram.tftp.server.BasicTftpServer;

import junit.framework.TestCase;


public class TimerTest extends TestCase implements SystemLogger.Injector
{

    // -- static fields
    private static int delay = 550;

    // -- members
    private ChannelSelector chanSelector;
    private TftpServer server;
    private TftpTestClient client;
    private Selector selector;
    private int startSize;

    // -- constructors

    public TimerTest(String arg0)
    {
        super(arg0);
    }

    // -- public methods

    public void testNormalData()
    {
        client.sendRrq();
        sleep(50);
        client.assertReceiveExactlyOne();
        client.sendAck();
        sleep(100);
        client.assertReceiveExactlyOne();
    }

    public void testRetransmitData()
    {
        client.sendRrq();
        firstPart();
        client.sendAck();
        sleep(50);
        client.assertReceiveExactlyOne();
        client.sendAck();
        lastPart();
    }

    public void testRetransmitAck()
    {
        client.sendWrq();
        firstPart();
        client.sendData();
        client.sendData();
        sleep(100);
        client.assertReceiveExactlyOne();
        lastPart();
    }

    // -- protected methods

    protected void setUp() throws Exception
    {
        chanSelector = ChannelSelectorImpl.getInstance(logger);
        server = BasicTftpServer.getInstance(logger);
        stop();
        chanSelector.start();
        server.start();
        client = new TftpTestClient();
        selector = ChannelSelectorAccessor.selector((ChannelSelectorImpl) chanSelector);
        startSize = selector.keys().size();
        ThreadUtils.sleep(50, logger);
    }

    protected void tearDown() throws Exception
    {
        stop();
    }

    // -- private methods
    private void stop()
    {
        server.stop();
        chanSelector.stop();
    }

    private void sleep(long time)
    {
        try
        {
            Thread.sleep(time);
        }
        catch (InterruptedException e)
        {
            logger.error("Interrupted sleep. ", e);
            throw new WrapperException(e);
        }
    }

    private void firstPart()
    {
        sleep(50);
        client.assertReceiveExactlyOne();
        sleep(delay);
        // retransmit
        client.assertReceiveExactlyOne();
    }

    private void lastPart()
    {
        sleep(delay);
        client.assertReceiveExactlyOne();

        // after 1 retry (nioagent.properties) close connection
        sleep(delay);
        client.assertClosed();
        selector.wakeup();
        sleep(500);
        assertEquals(startSize, selector.keys().size());
    }

}
