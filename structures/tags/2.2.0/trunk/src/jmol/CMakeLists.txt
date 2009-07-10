#################################################################
#                   Local variable settings                     #
#################################################################
set(LOCAL_TARGET jmol)
message(STATUS "Generating ${LOCAL_TARGET} Makefile")

file(GLOB jmol_SRCS *.jar *.js)
set(jmol_SRCS
    ${jmol_SRCS}
    COPYRIGHT.txt
    LICENSE.txt
    README.txt
)
set(jmol_files "")

add_custom_target(${LOCAL_TARGET} ALL)

#################################################################
#                       jmol file handle                       #
#################################################################
foreach(jmol_SRC_FILE ${jmol_SRCS})
  get_filename_component(jmol_FILE ${jmol_SRC_FILE} NAME)

  add_custom_command(TARGET ${LOCAL_TARGET}
                   COMMAND cp ${jmol_SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${jmol_FILE}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(jmol_files ${jmol_files} ${jmol_FILE})
endforeach(jmol_SRC_FILE)

#################################################################
#                         Install files                         #
#################################################################
install(FILES ${jmol_files} DESTINATION ${SHARE_HOME}/jmol)

