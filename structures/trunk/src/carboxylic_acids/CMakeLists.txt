#################################################################
#                   Local variables settings                    #
#################################################################
set(CHEM_GROUP "carboxylic_acids")

message(STATUS "Generating ${CHEM_GROUP} Makefile")

set(level "1")
set(index_files "")
set(chemical_structure_files "")
set(chemical_data_files "")

add_custom_target(${CHEM_GROUP} ALL)

#################################################################
#                       Index file handle                       #
#################################################################
foreach(lang ${AVAILABLE_LANG})
  set(index_files ${index_files} "${CMAKE_CURRENT_BINARY_DIR}/index_${lang}.html")
endforeach(lang)

#################################################################
#                     Structure file handle                     #
#################################################################
file(GLOB cml_SRCS *.cml)
set(chemical_structure_files "")

foreach(cml_SRC_FILE ${cml_SRCS})
  get_filename_component(cml_WE ${cml_SRC_FILE} NAME_WE)
  set(cml_FILE "${cml_WE}.cml")
  # add custom command to build mol files
  add_custom_command(TARGET ${CHEM_GROUP}
                     COMMAND cp ${cml_SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${cml_FILE}
                     WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(chemical_structure_files ${chemical_structure_files} "${CMAKE_CURRENT_BINARY_DIR}/${cml_FILE}")

  if(OPENBABEL2_EXECUTABLE_FOUND)
    # Generate mol files
    set(mol_FILE "${cml_WE}.mol")
    add_custom_command(TARGET ${CHEM_GROUP}
                       COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml_FILE} -omol ${mol_FILE}
                       WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set(chemical_structure_files ${chemical_structure_files} "${CMAKE_CURRENT_BINARY_DIR}/${mol_FILE}")
    # Generate smi files
    set(smi_FILE "${cml_WE}.smi")
    add_custom_command(TARGET ${CHEM_GROUP}
                       COMMAND ${OPENBABEL2_EXECUTABLE} -icml ${cml_FILE} -osmi ${smi_FILE}
                       WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set(chemical_structure_files ${chemical_structure_files} "${CMAKE_CURRENT_BINARY_DIR}/${smi_FILE}")
  endif(OPENBABEL2_EXECUTABLE_FOUND)

endforeach(cml_SRC_FILE)

#################################################################
#                   Chemical datafile handle                    #
#################################################################
foreach(cml_FILE ${cml_SRCS})
  get_filename_component(cml_WE ${cml_FILE} NAME_WE)
  foreach(lang ${AVAILABLE_LANG})
      set(chemical_data_files ${chemical_data_files} "${CMAKE_CURRENT_BINARY_DIR}/${cml_WE}_${lang}.html")
  endforeach(lang)
endforeach(cml_FILE)

#################################################################
#                       Build XHTML files                       #
#################################################################
add_custom_command(TARGET ${CHEM_GROUP}
                   COMMAND ${PYTHON_EXECUTABLE} ${MAKEXHTMLFILES} ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/index.xml ${level} ${AVAILABLE_LANG}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

#################################################################
#                         Install files                         #
#################################################################
install(FILES ${index_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP})
install(FILES ${chemical_structure_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP})
install(FILES ${chemical_data_files} DESTINATION ${SHARE_HOME}/${CHEM_GROUP})

