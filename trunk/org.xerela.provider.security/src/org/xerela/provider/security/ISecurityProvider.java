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

package org.xerela.provider.security;

import java.util.List;

import javax.jws.WebParam;
import javax.jws.WebService;
import javax.jws.soap.SOAPBinding;

import org.xerela.server.security.ZPrincipal;
import org.xerela.server.security.ZRole;
import org.xerela.zap.security.ZInvocationSecurity;

/**
 * ISecurityProvider
 */
@WebService(name = "Security", targetNamespace = "http://www.xerela.org/server/security")
@SOAPBinding(style = SOAPBinding.Style.DOCUMENT, parameterStyle = SOAPBinding.ParameterStyle.WRAPPED)
public interface ISecurityProvider
{
    /**
     * Calling this method will logout the user that is invoking it.
     *
     */
    void logoutCurrentUser();

    /**
     * Get the ZPrincipal object for the user invoking this method.
     *
     * @return the ZPrincipal object of the current user
     */
    ZPrincipal getCurrentUser();

    /**
     * Create a new user.
     *
     * @param username the name of the user (required)
     * @param fullName the full name of the user (optional)
     * @param email the email address of the user (optional)
     * @param password the cleartext password of the user (required)
     * @param role the role of the user (required)
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void createUser(@WebParam(name = "username") String username,
                    @WebParam(name = "fullName") String fullName,
                    @WebParam(name = "email") String email,
                    @WebParam(name = "password") String password,
                    @WebParam(name = "role") String role);

    /**
     * Delete the specified user.
     *
     * @param username the name of the user (required)
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void deleteUser(@WebParam(name = "username") String username);

    /**
     * Update the user's information using the supplied ZPrincipal object.  Note that
     * the password cannot be changed via this method.  For password changes see the
     * @see changePassword method.
     *
     * @param username the name of the user (required)
     * @param fullName the full name of the user (optional)
     * @param email the email address of the user (optional)
     * @param role the role of the user (required)
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void updateUser(@WebParam(name = "username") String username,
                    @WebParam(name = "fullName") String fullName,
                    @WebParam(name = "email") String email,
                    @WebParam(name = "role") String role);

    /**
     * Get a user object.
     *
     * @param username the name of the user to get (required)
     * @return a user object or null
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    ZPrincipal getUser(@WebParam(name = "username") String username);

    /**
     * Get the list of users defined in the system.
     *
     * @return the list of users
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    List<ZPrincipal> listUsers();

    /**
     * Change the password of the specified user.
     *
     * @param username the name of the user to change the password of (required)
     * @param password the new cleartext password of the user (required)
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void changePassword(@WebParam(name = "username") String username, @WebParam(name = "password") String password);

    /**
     * Change the password of the user invoking this method.
     *
     * @param password the new password
     */
    void changeMyPassword(@WebParam(name = "password") String password);

    /**
     * Get the currently list of all permissions available in
     * the system.  Each permission in the list is a specially formatted
     * string containing an internal identifier and a localized display string
     * separated by an equal (=) sign.  This means that an equal sign cannot
     * be part of the identifer.
     * <pre>
     * identifier=Display String
     * </pre>
     * @return the list of permissions.
     */
    List<String> getAvailablePermissions();

    /**
     * Create a new role.
     *
     * @param role the name of the role
     * @param permissions the list of permissions comprising the role
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void createRole(@WebParam(name = "role") String role, @WebParam(name = "permissions") List<String> permissions);

    /**
     * Delete the specified role.
     *
     * @param role the name of the role to delete
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void deleteRole(@WebParam(name = "role") String role);

    /**
     * Get the specified role definition.
     *
     * @param role the name of the role
     * @return the role definition
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    ZRole getRole(@WebParam(name = "role") String role);

    /**
     * Update the specified role to contain the listed permissions.  Note this will
     * replace all existing permissions in the role.
     *
     * @param zrole the name of the role
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    void updateRole(@WebParam(name = "zrole") ZRole zrole);

    /**
     * Get the list of all roles currently available in the system.
     *
     * @return the list of roles
     */
    @ZInvocationSecurity(perm = "org.xerela.security.administer")
    List<ZRole> getAvailableRoles();

    /**
     * Get the Xerela license file.
     *
     * @return the license file
     */
    License getLicense();
}
