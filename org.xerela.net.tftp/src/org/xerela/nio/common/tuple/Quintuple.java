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

package org.xerela.nio.common.tuple;

public abstract class Quintuple<A, B, C, D, E> extends Quadruple<A, B, C, D>
{

    // -- fields
    protected final E e;

    // -- constructors
    protected Quintuple(final A a, final B b, final C c, final D d, final E e)
    {
        super(a, b, c, d);
        this.e = e;
        fields.add(e);
    }
}
