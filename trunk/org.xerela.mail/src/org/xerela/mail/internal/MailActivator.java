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

package org.xerela.mail.internal;

import java.net.URI;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

/**
 * MailActivator
 */
public class MailActivator implements BundleActivator
{
    /** {@inheritDoc} */
    public void start(BundleContext context) throws Exception
    {
        // Load the mail properties
        String configRoot = System.getProperty("osgi.configuration.area").replace(" ", "%20"); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
        String mailProps = configRoot + "mail/mail.properties"; //$NON-NLS-1$
        System.getProperties().load(URI.create(mailProps).toURL().openStream());
    }

    /** {@inheritDoc} */
    public void stop(BundleContext context) throws Exception
    {
    }
}
