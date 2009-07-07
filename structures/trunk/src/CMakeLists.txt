message(STATUS "Generating src Makefile")

set(level "0")
add_custom_target(index ALL)
set(index_files "")
set(main_index_files "")

#################################################################
#                       Index file handle                       #
#################################################################
foreach(lang ${AVAILABLE_LANG})
  set(index_files ${index_files} "${CMAKE_CURRENT_BINARY_DIR}/index_${lang}.html")
endforeach(lang)

#################################################################
#                    Main index file handle                     #
#################################################################
foreach(lang ${AVAILABLE_LANG})
  set(main_index_files ${main_index_files} "${CMAKE_CURRENT_BINARY_DIR}/name_index_${lang}.html")
  set(main_index_files ${main_index_files} "${CMAKE_CURRENT_BINARY_DIR}/formula_index_${lang}.html")
endforeach(lang)

#################################################################
#                       Build XHTML files                       #
#################################################################
add_custom_command(TARGET index
                   COMMAND ${PYTHON_EXECUTABLE} ${MAKEINDEXFILES} ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/index.xml ${level} ${AVAILABLE_LANG}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

add_custom_command(TARGET clean_xhtml
                   COMMAND rm *.html
                   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
#################################################################
#                         Install files                         #
#################################################################
install(FILES ${index_files} DESTINATION ${SHARE_HOME})
install(FILES ${main_index_files} DESTINATION ${SHARE_HOME})

#################################################################
#                       Add subdirectories                      #
#################################################################
add_subdirectory(acid_anhydrides)
add_subdirectory(alcohols)
add_subdirectory(aldehydes)
add_subdirectory(alkanes)
add_subdirectory(alkenes)
add_subdirectory(alkynes)
add_subdirectory(amides)
add_subdirectory(amines)
add_subdirectory(amino_acids)
add_subdirectory(aromatics)
add_subdirectory(carbamides)
add_subdirectory(carbohydrates)
add_subdirectory(carboxylic_acids)
add_subdirectory(drugs)
add_subdirectory(esters)
add_subdirectory(ethers)
add_subdirectory(fatty_acids)
add_subdirectory(haloalkanes)
add_subdirectory(heteroaromatics)
add_subdirectory(images)
add_subdirectory(jmol)
add_subdirectory(ketones)
add_subdirectory(macrocycles)
add_subdirectory(natural_products)
add_subdirectory(nitriles)
add_subdirectory(nitroalkanes)
add_subdirectory(nucleobases)
add_subdirectory(peptides)
add_subdirectory(polycyclic_alkanes)
add_subdirectory(polycyclic_aromatics)
add_subdirectory(styles)
add_subdirectory(sulfones)
add_subdirectory(sulfoxides)
add_subdirectory(thioethers)
add_subdirectory(thiols)
add_subdirectory(water)
