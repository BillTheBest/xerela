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

package org.xerela.zap.jta;

import javax.transaction.Status;
import javax.transaction.SystemException;
import javax.transaction.Transaction;
import javax.transaction.UserTransaction;

import org.apache.log4j.Logger;
import org.xerela.zap.jta.internal.JtaActivator;

public class TransactionElf
{
    private static final Logger LOGGER = Logger.getLogger(TransactionElf.class);
    private static final int FIVE_MINUTES = 5 * 60 * 1000;

    /**
     * Start or join a transaction.
     *
     * @return true if a new transaction was started (this means the caller "owns"
     *    the commit()), false if a transaction was joined.
     */
    public static boolean beginOrJoinTransaction()
    {
        boolean newTransaction = false;
        try
        {
            UserTransaction userTransaction = JtaActivator.getUserTransaction();
            newTransaction = userTransaction.getStatus() == Status.STATUS_NO_TRANSACTION;
            if (newTransaction)
            {
                userTransaction.setTransactionTimeout(FIVE_MINUTES);
                userTransaction.begin();
            }
        }
        catch (Exception e)
        {
            throw new RuntimeException("Unable to start transaction.", e); //$NON-NLS-1$
        }

        return newTransaction;
    }

    /**
     * Commit the current transaction.
     */
    public static void commit()
    {
        try
        {
            UserTransaction userTransaction = JtaActivator.getUserTransaction();
            if (userTransaction.getStatus() == Status.STATUS_ACTIVE && userTransaction.getStatus() != Status.STATUS_ROLLING_BACK)
            {
                userTransaction.commit();
            }
        }
        catch (Exception e)
        {
            LOGGER.warn("Transaction commit failed.", e); //$NON-NLS-1$
            throw new RuntimeException("Transaction commit failed.", e); //$NON-NLS-1$
        }
    }

    /**
     * Rollback the current transaction.
     */
    public static void rollback()
    {
        try
        {
            UserTransaction userTransaction = JtaActivator.getUserTransaction();
            if (userTransaction.getStatus() == Status.STATUS_ACTIVE)
            {
                JtaActivator.getUserTransaction().rollback();
            }
            else
            {
                LOGGER.warn("Request to rollback transaction when none was in active."); //$NON-NLS-1$
            }
        }
        catch (Exception e)
        {
            LOGGER.warn("Transaction rollback failed.", e); //$NON-NLS-1$
        }
    }

    /**
     * Suspend the current transaction and return it to the caller.
     *
     * @return the suspended Transaction
     */
    public static Transaction suspend()
    {
        try
        {
            Transaction suspend = JtaActivator.getTransactionManager().suspend();
            return suspend;
        }
        catch (SystemException e)
        {
            throw new RuntimeException("Unable to suspend current transaction", e); //$NON-NLS-1$
        }
    }

    /**
     * Resume the specified transaction.  If the transaction was never suspended, or was
     * already committed or rolled back, a RuntimeException will be thrown wrapping the
     * JTA originated exception.
     *
     * @param transaction the Transaction to resume
     */
    public static void resume(Transaction transaction)
    {
        try
        {
            JtaActivator.getTransactionManager().resume(transaction);
        }
        catch (Exception e)
        {
            throw new RuntimeException("Unable to resume transaction", e); //$NON-NLS-1$
        }
    }
}
