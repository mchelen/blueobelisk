#################################################################
#                   Local variable settings                     #
#################################################################
set(LOCAL_TARGET images)
message(STATUS "Generating ${LOCAL_TARGET} Makefile")

file(GLOB image_SRCS *.png *.ico)
set(image_files "")

add_custom_target(${LOCAL_TARGET} ALL)

#################################################################
#                       Image file handle                       #
#################################################################
foreach(image_SRC_FILE ${image_SRCS})
  get_filename_component(image_FILE ${image_SRC_FILE} NAME)

  add_custom_command(TARGET ${LOCAL_TARGET}
                   COMMAND cp ${image_SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${image_FILE}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(image_files ${image_files} ${image_FILE})
endforeach(image_SRC_FILE)

#################################################################
#                         Install files                         #
#################################################################
install(FILES ${image_files} DESTINATION ${SHARE_HOME}/images)
