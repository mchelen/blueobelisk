#################################################################
#                   Local variable settings                     #
#################################################################
set(LOCAL_TARGET styles)
message(STATUS "Generating ${LOCAL_TARGET} Makefile")

file(GLOB style_SRCS *.css)
set(style_files "")

add_custom_target(${LOCAL_TARGET} ALL)

#################################################################
#                       style file handle                       #
#################################################################
foreach(style_SRC_FILE ${style_SRCS})
  get_filename_component(style_FILE ${style_SRC_FILE} NAME)

  add_custom_command(TARGET ${LOCAL_TARGET}
                   COMMAND cp ${style_SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${style_FILE}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(style_files ${style_files} ${style_FILE})
endforeach(style_SRC_FILE)

#################################################################
#                         Install files                         #
#################################################################
install(FILES ${style_files} DESTINATION ${SHARE_HOME}/styles)
