==============================================================================
===                                  Jmol                                  ===
==============================================================================


Jmol is an open-source molecule viewer and editor written in Java.

Full information is available at http://www.jmol.org/

Usage questions and comments should be posted to jmol-users@lists.sourceforge.net

Development questions, suggestions and comments should be posted
to jmol-developers@lists.sf.net

List of files included:
-------------------

- README.txt
    This file.

- COPYRIGHT.txt
    Copyright informations.

- LICENSE.txt
    GNU LGPL (terms of license for use and distribution of Jmol).
		
- Jmol.js
    The utilities library, written in JavaScript language, that assists in 
    the preparation of web pages that use Jmol applet, without the need to 
    know and write detailed JmolApplet code.
    This library uses by default the split version of the applet (either
    unsigned or signed).
    Fully documented at http://jmol.org/jslibrary/ 

- JmolAppletSigned0.jar  and JmolApplet0_(severalSuffixes).jar
    The applet is divided up into several pieces according to their function, 
    so that if a page does not require a component, that component is 
    not downloaded from the server. It is still recommended that you put 
    all JmolApplet0*.jar files on your server, even if your page does not use 
    the capabilities provided by some of the files, because the pop-up menu 
    and Jmol console both allow users to access parts of Jmol you might 
    not have considered.
    The set of these files is equivalent to the single JmolAppletSigned.jar.
    However, users get a message asking if they want to accept the certificate
    for **each** of the loadable jar fils. For this reason, this version
    may not be of general use.
    This split version is the one that will be used by default if you use 
    Jmol.js. For that, use the simplest form of jmolInitialize(), just 
    indicating the folder containing the set of jar files:
    jmolInitialize("folder-containing-jar-files")
    for example:
      jmolInitialize(".")  (if jar files are in the same folder as the web page)
      jmolInitialize("../jmol") (if jar files are in a parallel folder, named 'jmol')

