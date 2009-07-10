# - Find OpenBabel2 executable
# This module find if OpenBabel2 executable is installed and determines where
# the executable is. It sets the following variables:
#
# OPENBABEL2_EXECUTABLE_FOUND - set to true if the OpenBabel2 executable is 
# found
# OPENBABEL2_EXECUTABLE - path to OpenBabel2 executable

# Copyright (c) 2007 Jerome Pansanel <j.pansanel@pansanel.net>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING file.

IF( OPENBABEL2_EXECUTABLE )
  # in cache already
  SET( OPENBABEL2_EXECUTABLE_FOUND TRUE )

ELSE( OPENBABEL2_EXECUTABLE )
  FIND_PROGRAM(OPENBABEL2_EXECUTABLE
               NAMES babel
               PATHS
               [HKEY_LOCAL_MACHINE\\SOFTWARE\\OpenBabel\\Current;BinPath]
  )

  SET(OPENBABEL2_EXECUTABLE_FOUND)
  IF(OPENBABEL2_EXECUTABLE)
    SET(OPENBABEL2_EXECUTABLE_FOUND ON)
  ENDIF(OPENBABEL2_EXECUTABLE)

ENDIF( OPENBABEL2_EXECUTABLE )

IF( NOT ${OPENBABEL2_EXECUTABLE_FOUND} )
  IF( ${OPENBABEL2EXE_FIND_REQUIRED} )
    MESSAGE( FATAL_ERROR "OpenBabel2 executable was not found on the system." )
  ENDIF( ${OPENBABEL2EXE_FIND_REQUIRED} )
ENDIF( NOT ${OPENBABEL2_EXECUTABLE_FOUND} )

  
