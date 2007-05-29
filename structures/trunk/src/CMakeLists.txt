MESSAGE( STATUS "Generating src Makefile")

SET(level "0")
SET(index_prefix "index")

FOREACH( lang ${AVAILABLE_LANG} )
  SET( xhtml_files ${xhtml_files} "${index_prefix}_${lang}.html" )
  SET( data_index_files ${data_index_files} "name_index_${lang}.html" )
  SET( data_index_files ${data_index_files} "formula_index_${lang}.html" )
ENDFOREACH( lang )

ADD_CUSTOM_COMMAND( OUTPUT ${xhtml_files}
                    COMMAND ${PYTHON_EXECUTABLE} ${PYHANDLER}
                    ${CMAKE_SOURCE_DIR}
		    "index.xml" ${level}
		    ${AVAILABLE_LANG}
)

ADD_CUSTOM_COMMAND( OUTPUT ${data_index_files}
                    COMMAND ${PYTHON_EXECUTABLE} ${PYDATAINDEXER}
		    ${CMAKE_CURRENT_SOURCE_DIR}
		    ${AVAILABLE_LANG}
)

ADD_CUSTOM_TARGET( xhtml ALL
                   DEPENDS ${xhtml_files} ${data_index_files} 
)

INSTALL(FILES ${xhtml_files} DESTINATION ${SHARE_HOME})
INSTALL(FILES ${data_index_files} DESTINATION ${SHARE_HOME})

ADD_SUBDIRECTORY( alcohols )
ADD_SUBDIRECTORY( aldehydes )
ADD_SUBDIRECTORY( alkanes )
ADD_SUBDIRECTORY( alkenes )
ADD_SUBDIRECTORY( alkynes )
ADD_SUBDIRECTORY( amides )
ADD_SUBDIRECTORY( amines )
ADD_SUBDIRECTORY( amino_acids )
ADD_SUBDIRECTORY( aromatics )
ADD_SUBDIRECTORY( carbamides )
ADD_SUBDIRECTORY( carbohydrates )
ADD_SUBDIRECTORY( carboxylic_acids )
ADD_SUBDIRECTORY( drugs )
ADD_SUBDIRECTORY( esters )
ADD_SUBDIRECTORY( ethers )
ADD_SUBDIRECTORY( fatty_acids )
ADD_SUBDIRECTORY( haloalkanes )
ADD_SUBDIRECTORY( heteroaromatics )
ADD_SUBDIRECTORY( images )
ADD_SUBDIRECTORY( jmol )
ADD_SUBDIRECTORY( ketones )
ADD_SUBDIRECTORY( macrocycles )
ADD_SUBDIRECTORY( nitriles )
ADD_SUBDIRECTORY( nitroalkanes )
ADD_SUBDIRECTORY( nucleobases )
ADD_SUBDIRECTORY( polycyclic_alkanes )
ADD_SUBDIRECTORY( polycyclic_aromatics )
ADD_SUBDIRECTORY( styles )
ADD_SUBDIRECTORY( sulfones )
ADD_SUBDIRECTORY( sulfoxides )
ADD_SUBDIRECTORY( thioethers )
ADD_SUBDIRECTORY( thiols )
ADD_SUBDIRECTORY( water )
