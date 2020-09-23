list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/externals/json-cmake")
include(../cmake/DoxypressCMake.cmake)

doxypress_project_load(DoxypressTest1.json)