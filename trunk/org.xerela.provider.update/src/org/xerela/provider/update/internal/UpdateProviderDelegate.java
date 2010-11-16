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
package org.xerela.provider.update.internal;

import javax.jws.WebService;

import org.xerela.provider.update.IUpdateProvider;

/**
 * Web service delegate for the update provider.
 */
@WebService(endpointInterface = "org.xerela.provider.update.IUpdateProvider", //$NON-NLS-1$
            serviceName = "UpdateService",
            portName = "UpdatePort")
public class UpdateProviderDelegate implements IUpdateProvider
{
    /** {@inheritDoc} */
    public boolean download(String crateId, String version, String forgeUrl)
    {
        return UpdateActivator.getUpdateProvider().download(crateId, version, forgeUrl);
    }

    /** {@inheritDoc} */
    public String getSummaryXml()
    {
        return UpdateActivator.getUpdateProvider().getSummaryXml();
    }
}
