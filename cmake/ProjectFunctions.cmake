##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_project_load
#
# .. code-block:: cmake
#
#    _doxypress_project_load(<project file name>
#
# Loads a given project file into the current TPA scope. Name of every resulting
# property is prefixed with ``doxypress.`` in order to avoid name clashes.
#
# Parameters:
#
# * ``_file_name`` a project file to load
##############################################################################
function(_doxypress_project_load _file_name)
    _doxypress_log(INFO "Loading project template ${_file_name}...")
    file(READ "${_file_name}" _contents)
    sbeParseJson(doxypress _contents)
    foreach (_property ${doxypress})
        TPA_set(${_property} "${${_property}}")
    endforeach ()
    TPA_set(${_DOXYPRESS_PROJECT_KEY} "${doxypress}")
    # clean up JSON variables
    sbeClearJson(doxypress)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_project_save
#
# .. code-block:: cmake
#
#    _doxypress_project_save(<project file name>)
#
# Saves a parsed JSON document into a given file. The JSON tree is taken
# from the current TPA scope. Any existing file with the same name will be
# overwritten.
#
# Parameters:
#
# * ``_file_name`` output file name
##############################################################################
function(_doxypress_project_save _file_name)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)

    _JSON_serialize("${_variables}" _json)
    _doxypress_log(INFO "Saving processed project file ${_file_name}...")
    file(WRITE "${_file_name}" ${_json})
endfunction()

function(_doxypress_get _property _out_var)
    _JSON_get("doxypress.${_property}" _json_value)
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()

function(_doxypress_set _property _value)
    _JSON_set(doxypress.${_property} "${_value}")
endfunction()

##############################################################################
# @brief Calls a function or a macro given its name. Writes actual call code
# into a temporary file, which is then included.
# @param[in] _id         name of the function or macro to call
# @param[in] _arg1       the first argument to `_id`
# @param[in] ARGN        arguments to pass to the callable `_id`
##############################################################################
macro(_doxypress_call _id _arg1)
    if (NOT COMMAND ${_id})
        message(FATAL_ERROR "Unsupported function/macro \"${_id}\"")
    else ()
        set(_helper "${CMAKE_BINARY_DIR}/helpers/macro_helper_${_id}.cmake")
        # todo get this back?
        #if (NOT EXISTS "${_helper}")
        if ("${_arg1}" MATCHES "^\"(.*)\"$")
            file(WRITE "${_helper}" "${_id}(${_arg1} ${ARGN})\n")
        else()
            file(WRITE "${_helper}" "${_id}(\"${_arg1}\" ${ARGN})\n")
        endif()
        #foreach(_arg ${ARGN})
        #    file(APPEND "${_helper}" "\"${_arg}\" ")
        #endforeach()
        #file(APPEND "${_helper}" ")\n")
        #endif ()
        include("${_helper}")
    endif ()
endmacro()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_find_directory
#
# .. code-block:: cmake
#
#   _doxypress_find_directory(<base directory> <names> <output variable>)
#
# Searches for a directory with a name from the given list. Sets the output
# variable to contain absolute path of every found directory.
#
# Parameters:
#
# * ``_base_dir`` a directory to search
# * ``_names`` directories to find under ``_base_dir``
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_find_directory _base_dir _names _out_var)
    set(_result "")
    foreach (_name ${_names})
        if (IS_DIRECTORY ${_base_dir}/${_name})
            _doxypress_log(DEBUG "Found directory ${_base_dir}/${_name}")
            list(APPEND _result ${_base_dir}/${_name})
        endif ()
    endforeach ()
    set(${_out_var} "${_result}" PARENT_SCOPE)
endfunction()

macro(_doxypress_check_latex)
    TPA_get(GENERATE_LATEX _generate_latex)
    if (_generate_latex AND NOT DEFINED LATEX_FOUND)
        _doxypress_log(INFO "LaTex generation requested, importing LATEX...")
        find_package(LATEX OPTIONAL_COMPONENTS MAKEINDEX PDFLATEX)
        if (NOT LATEX_FOUND)
            _doxypress_set("output-latex.generate-latex" false)
            _doxypress_log(WARN "LATEX was not found; skip LaTex generation.")
        endif()
    endif()
endmacro()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_find_inputs(_out_var)
#
# Collects input file names based on value of input parameters that control
# input sources:
# * If ``INPUTS`` is not empty, collects all files in the paths given by
# ``INPUTS``. Files are added to the resulting list directly, and directories
# are globbed. Puts the resulting list into ``_out_var``.
# * If ``INPUT_TARGET`` is not empty, takes include directories from
# the corresponding target. Every directory is then globbed to get the files.
# * If none of the above holds, an error is raised.
#
# Parameters:
#
# * ``_out_var`` the list of files in input sources
##############################################################################
function(_doxypress_find_inputs _out_var)
    TPA_get(INPUTS _inputs)
    TPA_get(INPUT_TARGET _input_target)

    set(_all_inputs "")
    if (_inputs)
        foreach (_dir ${_inputs})
            if (IS_DIRECTORY ${_dir})
                file(GLOB_RECURSE _inputs ${_dir}/*)
                list(APPEND _all_inputs "${_inputs}")
            else()
                list(APPEND _all_inputs "${_dir}")
            endif()
        endforeach ()
    elseif (_input_target)
        get_target_property(public_header_dirs
                ${_input_target}
                INTERFACE_INCLUDE_DIRECTORIES)
        foreach (_dir ${public_header_dirs})
            file(GLOB_RECURSE _inputs ${_dir}/*)
            list(APPEND _all_inputs "${_inputs}")
        endforeach ()
    else ()
        # todo better message
        message(FATAL_ERROR [=[
Either INPUTS or INPUT_TARGET must be specified as input argument
for `doxypress_add_docs`]=])
    endif ()

    set(${_out_var} "${_all_inputs}" PARENT_SCOPE)
endfunction()
