list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/externals/json-cmake")
include(../cmake/DoxypressCMake.cmake)

# doxypress_project_load(DoxypressTest1.json)
function(assert_same str1 str2)
    if (NOT "${str1}" STREQUAL "${str2}")
        message(SEND_ERROR "`${str1}` is not the same as `${str2}`")
    endif ()
endfunction()

function(assert_list_contains list1 el)
    if (NOT "${el}" IN_LIST list1)
        message(SEND_ERROR "${el} is not contained in ${list1}")
    endif ()
endfunction()

include(TestTPA.cmake)