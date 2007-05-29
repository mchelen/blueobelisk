MESSAGE( STATUS "Generating alcohols Makefile")

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
     1_1_1_3_3_3-hexafluoropropan-2-ol
     2_2_2-trifluoroethanol
     2-aminoethanol
     2-methylbutan-2-ol
     2-methylpropan-1-ol
     2-methylpropan-2-ol
     2R_3R_4R_5S-hexane-1_2_3_4_5_6-hexol
     2R-butan-2-ol
     2S-butan-2-ol
     2S-heptan-2-ol
     2S-hexan-2-ol
     2S-octan-2-ol
     2S-pentan-2-ol
     2-thioethanol
     3S-heptan-3-ol
     3S-hexan-3-ol
     3S-octan-3-ol
     4R-octan-4-ol
     but-2-yne-1_4-diol
     butan-1-ol
     cyclohexanol
     cyclopentanol
     decan-1-ol
     ethane-1_2-diol
     ethanol
     heptan-1-ol
     heptan-4-ol
     hexan-1-ol
     methanol
     nonan-1-ol
     octan-1-ol
     pentan-1-ol
     pentan-3-ol
     propan-1-ol
     propan-2-ol
     propane-1_2_3-triol
     Z-hex-3-en-1-ol
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/alcohols )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/alcohols )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/alcohols )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/alcohols )
