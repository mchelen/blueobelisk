#################################################################
#                   Local variable settings                     #
#################################################################
set(LOCAL_TARGET htdocs)
message(STATUS "Generating ${LOCAL_TARGET} Makefile")

file(GLOB htdocs_SRCS *.html)

set(htdocs_files "")

add_custom_target(${LOCAL_TARGET} ALL)

#################################################################
#                      htdocs file handle                       #
#################################################################
foreach(htdocs_SRC_FILE ${htdocs_SRCS})
  get_filename_component(htdocs_FILE ${htdocs_SRC_FILE} NAME)

  add_custom_command(TARGET ${LOCAL_TARGET}
                   COMMAND cp ${htdocs_SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${htdocs_FILE}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(htdocs_files ${htdocs_files} ${htdocs_FILE})
endforeach(htdocs_SRC_FILE)

#################################################################
#                         Install files                         #
#################################################################
install(FILES ${htdocs_files} DESTINATION ${SHARE_HOME}/htdocs)

