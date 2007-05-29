MESSAGE( STATUS "Generating styles Makefile")

SET( level "1" )

SET( xhtml_files "" )

SET( styles_files 
    style.css
)

INSTALL( FILES ${styles_files} DESTINATION ${SHARE_HOME}/styles )
