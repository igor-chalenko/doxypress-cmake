configure_file(source/conf.py ${CMAKE_CURRENT_BINARY_DIR}/conf.py)
configure_file(source/cmake.py ${CMAKE_CURRENT_BINARY_DIR}/cmake.py @ONLY)
add_custom_target(docs
        COMMAND doxypress
        COMMAND sphinx-build -b html source/ -c ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR}/sphinx-generated
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
