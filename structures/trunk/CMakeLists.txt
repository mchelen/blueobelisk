PROJECT( chemical-structures )

CMAKE_MINIMUM_REQUIRED(VERSION 2.2)

SET( VERSION 2.1 )


SET( CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules )

FIND_PACKAGE( PythonInterp REQUIRED )
SET( PYHANDLER ${CMAKE_SOURCE_DIR}/tools/index2xhtml.py )
SET( PYDATAINDEXER ${CMAKE_SOURCE_DIR}/tools/make_index.py )

FIND_PACKAGE( OpenBabel2Exe )

SET( AVAILABLE_LANG "en" "es" "de" "fr" "nl" )

SET( SHARE_HOME ${CMAKE_INSTALL_PREFIX}/share/chemical-structures )

ADD_SUBDIRECTORY( src )

