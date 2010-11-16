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

/**
 * TFTP packet constants.
 * 
 * @author Brian Edwards (bedwards@alterpoint.com)
 *
 */
public interface PacketConstants
{

    // -- opcodes
    public static final byte OPCODE_RRQ = 1;
    public static final byte OPCODE_WRQ = 2;
    public static final byte OPCODE_DATA = 3;
    public static final byte OPCODE_ACK = 4;
    public static final byte OPCODE_ERROR = 5;
    public static final byte OPCODE_OACK = 6;

    // -- initial ack blocknums
    public static final int FIRST_ACK_BLOCKNUM_SERVER = 1;
    public static final int FIRST_ACK_BLOCKNUM_CLIENT = 0;

    // -- error codes
    public static final int ERROR_CODE_FILE_NOT_FOUND = 1;

    // -- options
    public static final String OPTION_BLKSIZE = "blksize";
    public static final String OPTION_TIMEOUT = "timeout";

    // -- misc
    public static final int DATA_OFFSET = 4;
    public static final int DEFAULT_BLOCK_SIZE = 512;

}
