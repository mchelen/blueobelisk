SET( CHEM_GROUP "haloalkanes" )

MESSAGE( STATUS "Generating ${CHEM_GROUP} Makefile")

#
# Generic variables
#
# Directory deepness. Required for the link to images, styles and jmol
SET( level "1" )
# Set xhtml_files empty
SET( xhtml_files "" )

#
# Index file handle
#
# Set the prefix of the index file
SET( index_prefix "index" )
# Generate the names of html index files
SET( index_file "${index_prefix}.xml" )
FOREACH( lang ${AVAILABLE_LANG} )
  SET( xhtml_files ${xhtml_files} "${index_prefix}_${lang}.html" )
ENDFOREACH( lang )

#
# CML file handle
#
# Set the prefix list of the cml files
FILE(GLOB cml_SRCS *.cml)
# Generate the names of html cml files
FOREACH( cml_FILENAME ${cml_SRCS} )
  GET_FILENAME_COMPONENT(cml_WE ${cml_FILENAME} NAME_WE)
  FOREACH( lang ${AVAILABLE_LANG} )
      SET( xhtml_files ${xhtml_files} "${cml_WE}_${lang}.html" )
  ENDFOREACH( lang )
ENDFOREACH( cml_FILENAME )

#
# Custom file conversion
#
IF(OPENBABEL2_EXECUTABLE_FOUND)
  # Initialize all variables
  SET( mol_files "" )
  SET( smi_files "" )

  FOREACH( cml_FILENAME ${cml_SRCS} )
    GET_FILENAME_COMPONENT(cml_WE ${cml_FILENAME} NAME_WE)
    # add custom command to build mol files
    ADD_CUSTOM_COMMAND( OUTPUT ${cml_WE}.mol
                        COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml_FILENAME} -omol ${cml_WE}.mol
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    SET( mol_files ${mol_files} ${cml_WE}.mol )
    # add custom command to build smile files
    ADD_CUSTOM_COMMAND( OUTPUT ${cml_WE}.smi
                        COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml_FILENAME} -osmi ${cml_WE}.smi
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    SET( smi_files ${smi_files} ${cml_WE}.smi )
  ENDFOREACH( cml_FILENAME )

  # Add custom target for mol files
  ADD_CUSTOM_TARGET( mdl_mol ALL
                     DEPENDS ${mol_files}
  )
  # Add custom target for smiles
  ADD_CUSTOM_TARGET( smiles ALL
                     DEPENDS ${smi_files}
  )
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP} )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP} )
ENDIF(OPENBABEL2_EXECUTABLE_FOUND)

#
# Build target command
#
ADD_CUSTOM_COMMAND( OUTPUT ${xhtml_files}
                    COMMAND ${PYTHON_EXECUTABLE} ${PYHANDLER}
                    ${CMAKE_SOURCE_DIR}
                    ${index_file} ${level}
                    ${AVAILABLE_LANG}
)
ADD_CUSTOM_TARGET( xhtml ALL
                   DEPENDS ${xhtml_files}
)

#
# Install target command
#
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP} )
INSTALL( FILES ${cml_SRCS} DESTINATION ${SHARE_HOME}/${CHEM_GROUP} )
