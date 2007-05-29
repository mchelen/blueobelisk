MESSAGE( STATUS "Generating haloalkanes Makefile")

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
     1_1_1_2_2_2-hexafluoroethane
     1_1_1_2_2-pentafluoroethane
     1_1_1-trichloroethane
     1_1_2_2-tetrachloroethane
     1_3-dichloropropane
     1_4-dichlorobut-2-yne
     1-bromopropane
     1-chloro-1_1_2_2_2-pentafluoroethane
     1-chlorobutane
     1-chlorodecane
     1-chloroheptane
     1-chlorohexane
     1-chlorononane
     1-chlorooctane
     1-chloropentane
     1-chloropropane
     2-bromo-2-methylpropane
     2-bromopropane
     2-chloro-2-methylpropane
     2-chloropropane
     2S-2-bromobutane
     2S-2-chlorobutane
     3-chloropropanoxide
     3-chloropropene
     bromocyclohexane
     bromoethane
     bromoform
     bromomethane
     bromotrifluoromethane
     chloro-chloromethoxy_methane
     chlorocyclohexane
     chloroethane
     chloroform
     chloromethane
     dichloromethane
     difluoromethane
     tetrachloromethane
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
  INSTALL( FILES ${mol_files} DESTINATION ${SHARE_HOME}/haloalkanes )
  INSTALL( FILES ${smi_files} DESTINATION ${SHARE_HOME}/haloalkanes )
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
INSTALL( FILES ${xhtml_files} DESTINATION ${SHARE_HOME}/haloalkanes )
INSTALL( FILES ${cml_files} DESTINATION ${SHARE_HOME}/haloalkanes )
