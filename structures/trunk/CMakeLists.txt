project(chemical-structures)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)

cmake_minimum_required(VERSION 2.4.0)

#################################################################
#                    Define global variables                    #
#################################################################
set(VERSION 2.2)
set(AVAILABLE_LANG "en" "es" "de" "fr" "nl" "tw")
set(SHARE_HOME ${CMAKE_INSTALL_PREFIX}/share/chemical-structures)

#################################################################
#                        Python Settings                        #
#################################################################
find_package(PythonInterp REQUIRED)
set(MAKEINDEXFILES ${CMAKE_SOURCE_DIR}/tools/make_index_files.py)
set(MAKEXHTMLFILES ${CMAKE_SOURCE_DIR}/tools/make_xhtml_files.py)

#################################################################
#                      Open Babel Settings                      #
#################################################################
find_package(OpenBabel2Exe)

#################################################################
#                     Define global target                      #
#################################################################
add_custom_target(clean_xhtml)
add_custom_target(clean_structure)

#################################################################
#                      Add subdirectories                       #
#################################################################
add_subdirectory(src)

