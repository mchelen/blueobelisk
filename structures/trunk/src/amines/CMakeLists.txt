MESSAGE( STATUS "Generating amines Makefile")

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
     1_4-diazabicyclo_2_2_2_octane
     1H-azepine
     1R_2S-cyclohexane-1_2-diamine
     1S_2S-cyclohexane-1_2-diamine
     2-methylpropan-2-amine
     2S-butan-2-amine
     azane
     azepane
     butan-1-amine
     cyclohexanamine
     cyclopentamine
     decan-1-amine
     ethanamine
     heptan-1-amine
     hexan-1-amine
     methanamine
     morpholine
     N-ethylethanamine
     N-methylmethanamine
     N_N-diethylethanamine
     N_N-dimethylmethanamine
     N_N_N2_N2-tetramethylethane-1_2-diamine
     nonan-1-amine
     octan-1-amine
     pentan-1-amine
     pentane-1_5-diamine
     piperazine
     piperidine
     propan-1-amine
     propan-2-amine
     pyrrolidine
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/amines )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/amines )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/amines )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/amines )
