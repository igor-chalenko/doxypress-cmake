include(JSONParser)

##############################################################################
## @brief Loads a given JSON project file into TPA scope.
## @param[in] _file_name file to load
##############################################################################
function(doxypress_project_load _file_name)
    file(READ "${_file_name}" _contents)
    sbeParseJson(doxypress _contents)
    message(STATUS ${doxypress})
endfunction()
