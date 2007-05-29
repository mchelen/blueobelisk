MESSAGE( STATUS "Generating jmol Makefile")

SET( level "1" )

SET( xhtml_files "" )

SET( Jmol_files 
     COPYRIGHT.txt
     jmol
     JmolApplet0.jar
     JmolApplet1.jar
     JmolApplet2.jar
     JmolApplet3.jar
     JmolApplet4.jar
     JmolApplet5.jar
     JmolApplet6.jar
     JmolApplet_i18n.jar
     JmolApplet.jar
     JmolAppletSigned0.jar
     JmolAppletSigned1.jar
     JmolAppletSigned2.jar
     JmolAppletSigned3.jar
     JmolAppletSigned4.jar
     JmolAppletSigned5.jar
     JmolAppletSigned6.jar
     JmolAppletSigned_i18n.jar
     JmolAppletSigned.jar
     jmol.bat
     Jmol.jar
     Jmol.js
     jmol.mac
     jmol.sh
     LICENSE.txt
     README.txt
)

INSTALL( FILES ${Jmol_files} DESTINATION ${SHARE_HOME}/jmol )
