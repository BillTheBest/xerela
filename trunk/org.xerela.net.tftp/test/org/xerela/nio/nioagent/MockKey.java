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

package org.xerela.nio.nioagent;

import java.io.IOException;
import java.nio.channels.SelectableChannel;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.spi.AbstractSelectionKey;

import org.xerela.nio.common.SystemLogger;
import org.xerela.nio.nioagent.WrapperException;


public class MockKey extends AbstractSelectionKey implements SystemLogger.Injector
{
    // -- members
    private final SelectableChannel channel;
    private int interestOps;

    // -- constructors
    public MockKey(SelectableChannel channel)
    {
        this.channel = channel;
        interestOps = SelectionKey.OP_READ;
    }

    // -- public methods
    @Override
    public SelectableChannel channel()
    {
        return channel;
    }

    @Override
    public SelectionKey interestOps(int arg0)
    {
        interestOps = arg0;
        return this;
    }

    @Override
    public int interestOps()
    {
        return interestOps;
    }

    @Override
    public Selector selector()
    {
        try
        {
            return Selector.open();
        }
        catch (IOException e)
        {
            logger.error("Failed to open selector. ", e);
            throw new WrapperException(e);
        }
    }

    @Override
    public int readyOps()
    {
        return interestOps;
    }

}
