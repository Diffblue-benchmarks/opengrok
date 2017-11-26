/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * See LICENSE.txt included in this distribution for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at LICENSE.txt.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright (c) 2006, 2016, Oracle and/or its affiliates. All rights reserved.
 * Portions Copyright (c) 2017, Chris Fraire <cfraire@me.com>.
 */

/*
 * Cross reference a Lisp file
 */

package org.opensolaris.opengrok.analysis.lisp;

import org.opensolaris.opengrok.analysis.JFlexXref;
import org.opensolaris.opengrok.web.HtmlConsts;
import org.opensolaris.opengrok.web.Util;
%%
%public
%class LispXref
%extends JFlexXref
%unicode
%ignorecase
%int
%include CommonXref.lexh
%{
  private int nestedComment;

  @Override
  public void reset() {
      super.reset();
      nestedComment = 0;
  }
%}

Identifier = [\-\+\*\!\@\$\%\&\/\?\.\,\:\{\}\=a-zA-Z0-9_\<\>]+

File = [a-zA-Z] {FNameChar}+ "." ([a-zA-Z]+)

Number = ([0-9]+\.[0-9]+|[0-9][0-9]*|"#" [boxBOX] [0-9a-fA-F]+)

%state  STRING COMMENT SCOMMENT

%include Common.lexh
%include CommonURI.lexh
%include CommonPath.lexh
%%
<YYINITIAL>{

{Identifier} {
    String id = yytext();
    writeSymbol(id, Consts.kwd, yyline);
}

 {Number}        {
    disjointSpan(HtmlConsts.NUMBER_CLASS);
    out.write(yytext());
    disjointSpan(null);
 }

 \"     {
    yybegin(STRING);
    disjointSpan(HtmlConsts.STRING_CLASS);
    out.write(htmlize("\""));
 }
 ";"    {
    yybegin(SCOMMENT);
    disjointSpan(HtmlConsts.COMMENT_CLASS);
    out.write(";");
 }
}

<STRING> {
 \" {WhiteSpace} \"  { out.write(htmlize(yytext())); }
 \"     {
    yybegin(YYINITIAL);
    out.write(htmlize(yytext()));
    disjointSpan(null);
 }
 \\\\   { out.write("\\\\"); }
 \\\"   { out.write(htmlize("\\\"")); }
}

<YYINITIAL, COMMENT> {
 "#|"   { yybegin(COMMENT);
          if (nestedComment++ == 0) { disjointSpan(HtmlConsts.COMMENT_CLASS); }
          out.write("#|");
        }
 }

<COMMENT> {
 "|#"   { out.write("|#");
          if (--nestedComment == 0) {
            yybegin(YYINITIAL);
            disjointSpan(null);
          }
        }
}

<SCOMMENT> {
  {WhspChar}*{EOL} {
    yybegin(YYINITIAL);
    disjointSpan(null);
    startNewLine();
  }
}

<YYINITIAL, STRING, COMMENT, SCOMMENT> {
[&<>\'\"]    { out.write(htmlize(yytext())); }
{WhspChar}*{EOL} { startNewLine(); }
 {WhiteSpace}   { out.write(yytext()); }
 [!-~]  { out.write(yycharat(0)); }
 [^\n]      { writeUnicodeChar(yycharat(0)); }
}

<STRING, COMMENT, SCOMMENT> {
{FPath}
        { out.write(Util.breadcrumbPath(urlPrefix+"path=",yytext(),'/'));}

{File}
        {
        String path = yytext();
        out.write("<a href=\""+urlPrefix+"path=");
        out.write(path);
        appendProject();
        out.write("\">");
        out.write(path);
        out.write("</a>");}

{BrowseableURI}    {
          appendLink(yytext(), true);
        }

{FNameChar}+ "@" {FNameChar}+ "." {FNameChar}+
        {
          writeEMailAddress(yytext());
        }
}
