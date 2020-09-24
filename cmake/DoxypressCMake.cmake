include(JSONParser)

# We must run the following at "include" time, not at function call time,
# to find the path to this module rather than the path to a calling list file
get_filename_component(doxypress_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

include(${doxypress_dir}/TargetPropertyAccess.cmake)

##############################################################################
# @brief The JSON document is stored in TPA under this name.
##############################################################################
set(_DOXYPRESS_PROJECT_KEY "json.parsed")

include(${doxypress_dir}/DoxypressCommon.cmake)
include(${doxypress_dir}/TargetPropertyAccess.cmake)
include(${doxypress_dir}/JSONFunctions.cmake)

##############################################################################
## @brief Loads a given JSON project file into TPA scope.
## @param[in] _file_name a project file to load
##############################################################################
function(doxypress_project_load _file_name)
    file(READ "${_file_name}" _contents)
    sbeParseJson(doxypress _contents)
    foreach (_property ${doxypress})
        TPA_set(${_property} "${${_property}}")
    endforeach ()
    TPA_set(${_DOXYPRESS_PROJECT_KEY} "${doxypress}")
    TPA_get(${_DOXYPRESS_PROJECT_KEY} xxx)
endfunction()

##############################################################################
## @brief Saves a parsed JSON document into a given file. The JSON tree is taken
## from a TPA scope. Any existing file with the same name will be overwritten.
## @param[in] _file_name output file name
##############################################################################
function(doxypress_project_save _file_name)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)

    JSON_serialize("${_variables}" _json)
    file(WRITE "${_file_name}" ${_json})
endfunction()
