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

package org.xerela.provider.tools;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.osgi.framework.Bundle;
import org.xerela.provider.tools.internal.PluginsActivator;

/**
 * ScriptToolResourceServlet
 */
public class ScriptToolResourceServlet extends HttpServlet
{
    private static final long serialVersionUID = 1822037101624140324L;

    /** {@inheritDoc} */
    @Override
    public void init(ServletConfig config) throws ServletException
    {
        super.init(config);
    }

    /** {@inheritDoc} */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException
    {
        String toolName = req.getParameter("tool"); //$NON-NLS-1$
        String resource = req.getParameter("resource"); //$NON-NLS-1$

        if (toolName == null || resource == null)
        {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        ScriptPluginManager scriptToolManager = (ScriptPluginManager) PluginsActivator.getPluginManager(ScriptPluginManager.class.getName());
        PluginDescriptor toolDescriptor = scriptToolManager.getPluginDescriptor(toolName);
        if (toolDescriptor == null)
        {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        Bundle scriptBundle = toolDescriptor.getBundle();
        String bundlePath = toolDescriptor.getBundlePath();

        String resourcePath = String.format("%s/%s", bundlePath, resource); //$NON-NLS-1$
        URL entry = scriptBundle.getEntry(resourcePath);
        if (entry == null)
        {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        setContentType(resource, resp);

        ServletOutputStream outputStream = resp.getOutputStream();
        InputStream stream = entry.openStream();
        byte[] buf = new byte[1024];
        while (true)
        {
            int rc = stream.read(buf);
            if (rc <= 0)
            {
                break;
            }

            outputStream.write(buf, 0, rc);
        }

        outputStream.flush();
    }

    @SuppressWarnings("nls")
    private void setContentType(String resource, HttpServletResponse resp)
    {
        String res = resource.toLowerCase();
        if (res.endsWith(".gif"))
        {
            resp.setContentType("image/gif");
        }
        else if (res.endsWith(".jpg"))
        {
            resp.setContentType("image/jpeg");
        }
        else if (res.endsWith(".png"))
        {
            resp.setContentType("image/png");
        }
    }
}
