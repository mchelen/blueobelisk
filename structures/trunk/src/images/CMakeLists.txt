MESSAGE( STATUS "Generating images Makefile")

SET( level "1" )

SET( xhtml_files "" )

SET( images_files 
     alchemlogo.png
     bologo.png
     header_bg.png
     header.png
     download.png
)

INSTALL( FILES ${images_files} DESTINATION ${SHARE_HOME}/images )
