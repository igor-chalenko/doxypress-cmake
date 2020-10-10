add_custom_target(docs
        COMMAND sphinx-build -b html source/ -c ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR}/sphinx-generated
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
