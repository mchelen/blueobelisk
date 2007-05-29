MESSAGE( STATUS "Generating ketones Makefile")

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
# CML files handle
#
# Set the prefix list of the cml files
SET( cml_prefix
     1_1_1_3_3_3-hexafluoropropanone
     but-3-en-2-one
     butanone
     cyclohex-2-en-1-one
     cyclohexa-2_4-diene-1_6-dione
     cyclohexa-2_5-diene-1_4-dione
     cyclohexanone
     cyclopent-2-en-1-one
     cyclopentanone
     heptan-2-one
     heptan-3-one
     heptan-4-one
     hexan-2-one
     hexan-3-one
     octan-2-one
     octan-3-one
     octan-4-one
     pentan-2-one
     pentan-3-one
     propanone
     pyran-2-one
     pyran-4-one
     Z-4-hydroxypent-3-en-2-one
)
# Generate the names of html cml files
SET( cml_files "" )
FOREACH( cml ${cml_prefix} )
  SET( cml_files ${cml_files} "${cml}.cml" )
  FOREACH( lang ${AVAILABLE_LANG} )
      SET( xhtml_files ${xhtml_files} "${cml}_${lang}.html" )
  ENDFOREACH( lang )
ENDFOREACH( cml )

#
# Custom file conversion
#
IF(OPENBABEL2_EXECUTABLE_FOUND)
  # Initialize all variables
  SET( mol_files "" )
  SET( smi_files "" )

  FOREACH( cml ${cml_prefix} )
    # add custom command to build mol files
    ADD_CUSTOM_COMMAND( OUTPUT ${cml}.mol
                        COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml}.cml -omol ${cml}.mol
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    SET( mol_files ${mol_files} ${cml}.mol )
    # add custom command to build smile files
    ADD_CUSTOM_COMMAND( OUTPUT ${cml}.smi
                        COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml}.cml -osmi ${cml}.smi
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    SET( smi_files ${smi_files} ${cml}.smi )
  ENDFOREACH( cml )

  # Add custom target for mol files
  ADD_CUSTOM_TARGET( mdl_mol ALL
                     DEPENDS ${mol_files}
  )
  # Add custom target for smiles
  ADD_CUSTOM_TARGET( smiles ALL
                     DEPENDS ${smi_files}
  )
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/ketones )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/ketones )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/ketones )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/ketones )
