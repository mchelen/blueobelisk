MESSAGE( STATUS "Generating aromatics Makefile")

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
     1_2-xylene
     1_3_5-trichloro-2-methoxybenzene
     1_3_5-trimethylbenzene
     1_3-xylene
     1_4-xylene
     1-chloro-2-ethenylbenzene
     1-chloro-2-methoxybenzene
     1-chloro-3-methoxybenzene
     1-chloro-4-methoxybenzene
     1-phenylbutan-1-one
     1S_2R-1_2-diphenylethane-1_2-diol
     2_2-dimethyl-3H-benzofuran-7-yl_N-methylcarbamate
     2_3_4_5_6-pentachlorophenol
     2_3-dimethylphenol
     2_4_6-trichlorophenol
     2_4_6-trimethylaniline
     2_4_6-trinitrotoluene
     2_4-diaminotoluene
     2_4-dimethylphenol
     2_5-dimethylphenol
     2_6-diaminotoluene
     2_6-dimethylphenol
     2-bromophenol
     2-chloro-4-nitroaniline
     2-chloro-5-methylphenol
     2-chlorophenol
     2-hydroxybenzaldehyde
     2-phenylacetic_acid
     2-phenylethanol
     2-pyridin-2-ylpyridine
     3_4-dimethylphenol
     3_5-dimethylphenol
     3-bromophenol
     3-chlorophenol
     3-pyridin-3-ylpyridine
     4_bis_4-dimethylaminophenyl_methylene-2_5-cyclohexadien-1-iminium
     4-bromo-5-methyl-2-propan-2-yl-phenol
     4-bromophenol
     4-chloro-2-methylphenol
     4-chloro-3-methylphenol
     4-chloroaniline
     4-chlorophenol
     4-dimethylaminobenzaldehyde
     4-methoxybenzaldehyde
     4-methylbenzoic_acid
     4-octylphenol
     4-pyridin-4-ylpyridine
     5-chloro-2-2_4-dichlorophenoxy_phenol
     aniline
     anisole
     benzaldehyde
     benzamide
     benzene-1_2-diamine
     benzene-1_2-diol
     benzene-1_3-diamine
     benzene-1_3-diol
     benzene-1_4-diamine
     benzene-1_4-diol
     benzene
     benzhydrylbenzene
     benzoic_acid
     benzonitrile
     benzoyl_chloride
     bromobenzene
     chlorobenzene
     E-2-chloroethenyl_benzene
     E-2-phenylethenyl_benzene
     ethoxybenzene
     nitrobenzene
     N_N-dimethylaniline
     phenol
     phenylmethanol
     toluene
     triphenylmethanol
     tris_4-aminophenyl_methanol
     tris_4-cyanophenyl_methane
     tris_4-cyanophenyl_methanol
     tris_4-dimethylaminophenyl_methanol
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/aromatics )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/aromatics )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/aromatics )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/aromatics )
