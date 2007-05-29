MESSAGE( STATUS "Generating amino_acids Makefile")

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
     2-aminoacetic_acid
     2R-2_6-diaminohexanoic_acid
     2R-2-amino-3-1H-indol-3-yl_propanoic_acid
     2R-2-amino-3-3H-imidazol-4-yl_propanoic_acid
     2R-2-amino-3-4-hydroxyphenyl_propanoic_acid
     2R-2-amino-3-carbamoyl-propanoic_acid
     2R-2-amino-3-hydroxy-propanoic_acid
     2R-2-amino-3-methyl-butanoic_acid
     2R-2-amino-3-phenyl-propanoic_acid
     2R-2-amino-3-sulfanyl-propanoic_acid
     2R-2-amino-4-carbamoyl-butanoic_acid
     2R-2-amino-4-methyl-pentanoic_acid
     2R-2-amino-4-methylsulfanyl-butanoic_acid
     2R-2-amino-5-diaminomethylideneaminopentanoic_acid
     2R-2-aminobutanedioic_acid
     2R-2-aminopentanedioic_acid
     2R-2-aminopropanoic_acid
     2R_3R-2-amino-3-hydroxy-butanoic_acid
     2R_3R-2-amino-3-methyl-pentanoic_acid
     2R_3S-2-amino-3-hydroxy-butanoic_acid
     2R-pyrrolidine-2-carboxylic_acid
     2S-2_6-diaminohexanoic_acid
     2S-2-amino-3-1H-indol-3-yl_propanoic_acid
     2S-2-amino-3-3H-imidazol-4-yl_propanoic_acid
     2S-2-amino-3-4-hydroxyphenyl_propanoic_acid
     2S-2-amino-3-carbamoyl-propanoic_acid
     2S-2-amino-3-hydroxy-propanoic_acid
     2S-2-amino-3-methyl-butanoic_acid
     2S-2-amino-3-phenyl-propanoic_acid
     2S-2-amino-3-sulfanyl-propanoic_acid
     2S-2-amino-4-carbamoyl-butanoic_acid
     2S-2-amino-4-methyl-pentanoic_acid
     2S-2-amino-4-methylsulfanyl-butanoic_acid
     2S-2-amino-5-diaminomethylideneaminopentanoic_acid
     2S-2-aminobutanedioic_acid
     2S-2-aminopentanedioic_acid
     2S-2-aminopropanoic_acid
     2S_3R-2-amino-3-hydroxy-butanoic_acid
     2S_3R-2-amino-3-methyl-pentanoic_acid
     2S_3S-2-amino-3-methyl-pentanoic_acid
     2S-pyrrolidine-2-carboxylic_acid
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/amino_acids )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/amino_acids )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/amino_acids )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/amino_acids )
