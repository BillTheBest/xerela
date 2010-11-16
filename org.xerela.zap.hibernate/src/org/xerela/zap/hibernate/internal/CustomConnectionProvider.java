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

package org.xerela.zap.hibernate.internal;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

import javax.sql.DataSource;

import org.hibernate.HibernateException;
import org.hibernate.connection.ConnectionProvider;
import org.osgi.framework.BundleContext;
import org.osgi.framework.Filter;
import org.osgi.util.tracker.ServiceTracker;

/**
 * CustomConnectionProvider
 */
public class CustomConnectionProvider implements ConnectionProvider
{
    private static BundleContext bundleContext;
    private ServiceTracker tracker;

    /**
     * public no-args constructor, per Hibernate requirements.
     */
    public CustomConnectionProvider()
    {
    }

    /** {@inheritDoc} */
    public synchronized void close()
    {
        tracker.close();
        tracker = null;
    }

    /** {@inheritDoc} */
    public void closeConnection(Connection connection) throws SQLException
    {
        connection.close();
    }

    /** {@inheritDoc} */
    public void configure(Properties props)
    {
        try
        {
            String filterSpec = "(objectClass=" + DataSource.class.getName() + ")";
            String dsUniqueName = props.getProperty("datasource.uniqueName");
            if (dsUniqueName != null)
            {
                filterSpec = "(&" + filterSpec + "(service.pid=" + dsUniqueName + "))";
            }
            Filter filter = bundleContext.createFilter(filterSpec);

            tracker = new ServiceTracker(bundleContext, filter, null);
            tracker.open();
        }
        catch (Exception ex)
        {
            throw new HibernateException("Hibernate custom connection configuration failed", ex);
        }
    }

    /** {@inheritDoc} */
    public Connection getConnection() throws SQLException
    {
        try
        {
            if (tracker == null)
            {
                throw new SQLException("DataSource Service Tracker has not be initialized.");
            }
            else
            {
                return ((DataSource) tracker.getService()).getConnection();
            }
        }
        catch (Exception e)
        {
            throw new SQLException("Unable to obtain DataSource: " + e.getMessage()); //$NON-NLS-1$
        }
    }

    /** {@inheritDoc} */
    public boolean supportsAggressiveRelease()
    {
        return true;
    }

    /**
     * Initialize this class with the BundleContext.  This is used
     * later to set the context class loader when doing JNDI lookups.
     *
     * @param context the ClassLoader used to load our parent activator
     */
    static void init(BundleContext context)
    {
        bundleContext = context;

    }
}
