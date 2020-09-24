include(JSONParser)

# We must run the following at "include" time, not at function call time,
# to find the path to this module rather than the path to a calling list file
get_filename_component(doxypress_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

include(${doxypress_dir}/TargetPropertyAccess.cmake)

##############################################################################
## @brief Loads a given JSON project file into TPA scope.
## @param[in] _file_name file to load
##############################################################################
function(doxypress_project_load _file_name)
    file(READ "${_file_name}" _contents)
    sbeParseJson(doxypress _contents)
    message(STATUS ${doxypress})
endfunction()
