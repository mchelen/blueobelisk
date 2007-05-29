MESSAGE( STATUS "Generating alkenes Makefile")

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
     2-methylbut-2-ene
     2-methylbuta-1_3-diene
     3E-penta-1_3-diene
     3Z_3-ethylhepta-1_3-diene
     3Z-penta-1_3-diene
     but-1-ene
     cyclohepta-1_3_5-triene
     cyclohepta-1_3-diene
     cyclohepta-1_4-diene
     cyclohexa-1_3-diene
     cyclohexa-1_4-diene
     cyclohexene
     cycloocta-1_3_5_7-tetraene
     cycloocta-1_3_5-triene
     cycloocta-1_3-diene
     cyclopenta-1_3-diene
     cyclopentene
     E-but-2-ene
     E-hept-2-ene
     E-hept-3-ene
     E-hex-2-ene
     E-hex-3-ene
     E-oct-2-ene
     E-oct-3-ene
     E-oct-4-ene
     E-pent-2-ene
     ethene
     hept-1-ene
     hex-1-ene
     oct-1-ene
     pent-1-ene
     propene
     Z-but-2-ene
     Z-cycloheptene
     Z-cyclooctene
     Z-hept-2-ene
     Z-hept-3-ene
     Z-hex-2-ene
     Z-hex-3-ene
     Z-oct-2-ene
     Z-oct-3-ene
     Z-oct-4-ene
     Z-pent-2-ene
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/alkenes )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/alkenes )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/alkenes )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/alkenes )
