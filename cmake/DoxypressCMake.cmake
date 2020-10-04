#.rst:
# DoxypressCMake
# --------------
#
# .. code-block:: cmake
#
#   find_package(DoxypressCMake)
#
# Supplies a function for building documentation with ``Doxypress``:
#
# .. cmake:command:: doxypress_add_docs
#
# .. code-block:: cmake
#
#    doxypress_add_docs([PROJECT_FILE] <name>
#                       [INPUT_TARGET] <name>
#                       [EXAMPLES] <directories>
#                       [INPUTS] <directories>
#                       [INSTALL_COMPONENT] <name>
#                       [GENERATE_HTML]
#                       [GENERATE_LATEX]
#                       [GENERATE_PDF]
#                       [GENERATE_XML]
#                       [OUTPUT_DIRECTORY] <directory>)
#
# Generates blah blah...

include(JSONParser)

# We must run the following at "include" time, not at function call time,
# to find the path to this module rather than the path to a calling list file
get_filename_component(doxypress_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

include(${doxypress_dir}/TargetPropertyAccess.cmake)
include(${doxypress_dir}/DoxypressTargets.cmake)
include(${doxypress_dir}/DoxypressParameters.cmake)

##############################################################################
# @brief The JSON document is stored in TPA under this name.
##############################################################################
set(_DOXYPRESS_PROJECT_KEY "json.parsed")
set(_DOXYPRESS_JSON_PATHS_KEY "json.paths")
set(_DOXYPRESS_INPUTS "inputs")

include(${doxypress_dir}/DoxypressCommon.cmake)
include(${doxypress_dir}/TargetPropertyAccess.cmake)
include(${doxypress_dir}/JSONFunctions.cmake)

##############################################################################
## @brief Generates documentation using Doxypress.
## Performs the following tasks:
## * Creates a target `${INPUT_TARGET}.doxypress` to run `Doxypress`; here
## `INPUT_TARGET` is the argument, given to this function, or its default value
## `${PROJECT_NAME}` if none given.
## * Creates other targets to open the generated documentation
## (`index.html`, 'refman.tex' or `refman.pdf`). An application that is
## configured to open the files of corresponding type is used.
## * Adds the generated files to the `install` target, if a non-empty value
## of `INSTALL_COMPONENT` was given.
##############################################################################
function(doxypress_add_docs)
    # initialize parameter/property descriptions
    _doxypress_params_init()
    # parse input arguments
    _doxypress_params_parse(${ARGN})
    # get the project file name
    TPA_get(PROJECT_FILE _project_file)
    # now we have the JSON template to load and parse
    _doxypress_project_load(${_project_file})
    # update JSON properties
    _doxypress_project_update()
    # create name for the processed project file
    _doxypress_project_generated_name(${_project_file} _file_name)
    # save processed project file
    _doxypress_project_save("${_file_name}")
    # create doxypress target
    _doxypress_create_targets("${_project_file}" "${_file_name}")
    TPA_get(INSTALL_COMPONENT _install_component)

    if (_install_component)
        _doxypress_log(DEBUG "CMAKE_INSTALL_DOCDIR = ${CMAKE_INSTALL_DOCDIR}")
        _doxypress_install_docs("${CMAKE_INSTALL_DOCDIR}" ${_install_component})
    endif()

    # export input arguments if requested
    # doxypress_export_input_args()

    # clean up the property storage target created by this function
    TPA_clear_scope()
    # clean up JSON variables
    sbeClearJson(doxypress)
endfunction()

##############################################################################
## @brief Loads a given JSON project file into TPA scope.
## @param[in] _file_name a project file to load
##############################################################################
function(_doxypress_project_load _file_name)
    _doxypress_log(INFO "Loading project template ${_file_name}...")
    file(READ "${_file_name}" _contents)
    sbeParseJson(doxypress _contents)
    foreach (_property ${doxypress})
        TPA_set(${_property} "${${_property}}")
    endforeach ()
    TPA_set(${_DOXYPRESS_PROJECT_KEY} "${doxypress}")
endfunction()

##############################################################################
## @brief Saves a parsed JSON document into a given file. The JSON tree is taken
## from a TPA scope. Any existing file with the same name will be overwritten.
## @param[in] _file_name output file name
##############################################################################
function(_doxypress_project_save _file_name)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)

    _JSON_serialize("${_variables}" _json)
    _doxypress_log(INFO "Saving processed project file ${_file_name}...")
    file(WRITE "${_file_name}" ${_json})
endfunction()

##############################################################################
# @brief Prepares argument parsing context.
##############################################################################
function(_doxypress_params_init)
    _doxypress_param_string(PROJECT_FILE
            UPDATER "update_project_file"
            DEFAULT "${doxypress_dir}/DoxypressCMake.json")
    _doxypress_param_string(INPUT_TARGET SETTER "set_input_target")
    _doxypress_param_string(INSTALL_COMPONENT)
    _doxypress_param_option(GENERATE_PDF DEFAULT false)

    _doxypress_json_property(
            "output-xml.generate-xml"
            INPUT_OPTION GENERATE_XML
            DEFAULT false)
    _doxypress_json_property(
            "output-latex.generate-latex"
            INPUT_OPTION GENERATE_LATEX
            DEFAULT false)
    _doxypress_json_property(
            "output-html.generate-html"
            INPUT_STRING GENERATE_HTML
            DEFAULT true)

    _doxypress_json_property("general.output-dir"
            INPUT_STRING OUTPUT_DIRECTORY
            UPDATER "update_output_dir"
            DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/doxypress-generated")

    _doxypress_json_property("input.input-source"
            INPUT_LIST INPUTS
            UPDATER "update_input_source")

    _doxypress_json_property("input.example-source"
           INPUT_LIST EXAMPLE_DIRECTORIES
           SETTER "set_example_source"
           UPDATER "update_example_source")

    _doxypress_json_property("dot.have-dot" SETTER "set_have_dot" OVERWRITE)
    _doxypress_json_property("dot.dot-path" SETTER "set_dot_path" OVERWRITE)
    _doxypress_json_property("dot.dia-path" SETTER "set_dia_path" OVERWRITE)
    _doxypress_json_property("messages.warn-format"
            SETTER "set_warn_format"
            OVERWRITE)
    _doxypress_json_property("output-latex.makeindex-cmd-name"
            SETTER "set_makeindex_cmd_name"
            OVERWRITE)
    _doxypress_json_property("output-latex.latex-cmd-name"
            SETTER "set_latex_cmd_name"
            OVERWRITE)

    _doxypress_json_property("messages.quiet" DEFAULT true)
    _doxypress_json_property("messages.warnings" DEFAULT true)

    set("project.project-name" "${PROJECT_NAME}" PARENT_SCOPE)
    set("project.project-version" ${PROJECT_VERSION} PARENT_SCOPE)
    set("project.project-brief" ${PROJECT_DESCRIPTION} PARENT_SCOPE)

    set("output-latex.latex-hyper-pdf" true PARENT_SCOPE)
    set("output-latex.latex-pdf" true PARENT_SCOPE)
    set("output-latex.latex-batch-mode" true PARENT_SCOPE)
    set("output-html.html-output" "html" PARENT_SCOPE)
    set("output-html.html-file-extension" ".html" PARENT_SCOPE)
    set("output-xml.xml-output" "xml" PARENT_SCOPE)
    set("output-latex.latex-output" "latex" PARENT_SCOPE)
    set("input.input-recursive" true PARENT_SCOPE)
    set("input.example-recursive" true PARENT_SCOPE)
endfunction()

macro(_doxypress_project_update)
    TPA_get(GENERATE_LATEX _generate_latex)
    if ("${_generate_latex}" AND NOT DEFINED LATEX_FOUND)
        _doxypress_log(INFO "LaTex generation requested, importing LATEX...")
        find_package(LATEX OPTIONAL_COMPONENTS MAKEINDEX PDFLATEX)
        if (NOT LATEX_FOUND)
            _JSON_set("doxypress.output-latex.generate-latex" false)
            message(STATUS "LATEX was not found; skip LaTex generation.")
        endif()
    endif()

    TPA_get("${_DOXYPRESS_JSON_PATHS_KEY}" _properties)

    foreach (_property ${_properties})
        _doxypress_json_update_property(${_property})
    endforeach ()
endmacro()

function(_doxypress_json_update_property _property)
    # _doxypress_cut_prefix(${_property} xxx)
    TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_SETTER _setter)
    TPA_get(${_property}_DEFAULT _default)
    TPA_get(${_property}_INPUT _input_arg_name)
    TPA_get(${_property}_OVERWRITE _overwrite)

    set(_input_value "")
    if (_input_arg_name)
        TPA_get(${_input_arg_name} _input_value)

        # convert CMake booleans to JSON's
        if ("${_input_value}" STREQUAL TRUE)
            set(_input_value true)
        endif()
        if ("${_input_value}" STREQUAL FALSE)
            set(_input_value false)
        endif()
        _doxypress_action(${_property} input "${_input_value}")
    endif ()
    set(_value "${_input_value}")

    _doxypress_log(DEBUG "[json_update_property] ${_property}")

    if ("${_value}" STREQUAL "")
        _JSON_get(doxypress.${_property} _value)
        _doxypress_action(${_property} source "${_value}")
        _doxypress_log(DEBUG "[json_update_property] value in JSON = ${_value}")
    endif ()
    if (_value STREQUAL "" OR _overwrite)
        if (_setter)
            _doxypress_log(DEBUG "call setter ${_setter}")
            _doxypress_call(_doxypress_${_setter} _value)
        endif ()
        if (_updater)
            _doxypress_log(DEBUG "call updater ${_updater}")
            _doxypress_call(_doxypress_${_updater} "${_value}" _value)
        endif ()
        if (_value STREQUAL "")
            # if no default, _value is left empty
            if (NOT _default STREQUAL "")
                set(_value "${_default}")
                _doxypress_action(${_property} default "${_value}")
                _doxypress_log(DEBUG "[default] ${_property} = ${_default}")
            endif ()
        endif ()
    else ()
        # if it's an array merge with input if any
        TPA_get(doxypress.${_property} _json_value)
        if (NOT _input_value STREQUAL "" AND "${_json_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
            _JSON_get(doxypress.${_property} _json_value)
            foreach(_val ${_value})
                list(APPEND _json_value "${_val}")
            endforeach()
            set(_value ${_json_value})
            _doxypress_action(${_property} merge "${_value}")
        endif()

        if (_updater)
            _doxypress_call(_doxypress_${_updater} "${_value}" _value)
        endif ()
        # _doxypress_log(DEBUG "[json] ${_property} = ${_value}")
    endif ()

    _JSON_set(doxypress.${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_arg_name)
        TPA_set(${_input_arg_name} "${_value}")
    endif ()
endfunction()

##############################################################################
## @brief Sets `output-latex.latex-cmd-name` to the value of
## `PDFLATEX_COMPILER` set by `find_package(LATEX)`.
##############################################################################
function(_doxypress_set_latex_cmd_name _out_var)
    if (NOT "${PDFLATEX_COMPILER}" STREQUAL PDFLATEX_COMPILER-NOTFOUND)
        set(${_out_var} "${PDFLATEX_COMPILER}" PARENT_SCOPE)
        _doxypress_action("output-latex.latex-cmd-name"
                setter "${PDFLATEX_COMPILER}")
    else()
        if (LATEX_FOUND)
            set(${_out_var} "${LATEX_COMPILER}" PARENT_SCOPE)
            _doxypress_action("output-latex.latex-cmd-name"
                    setter "${LATEX_COMPILER}")
        else()
            set(${_out_var} "" PARENT_SCOPE)
        endif()
    endif ()
endfunction()

function(_doxypress_update_project_file _project_file _out_var)
    set(_result "")
    if (NOT IS_ABSOLUTE ${_project_file})
        get_filename_component(_result
                ${CMAKE_CURRENT_SOURCE_DIR}/${_project_file} ABSOLUTE)
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

function(_doxypress_set_input_target _out_var)
    if (TARGET ${PROJECT_NAME})
        set(${_out_var} ${PROJECT_NAME} PARENT_SCOPE)
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif()
endfunction()

##############################################################################
# @brief Sets `dia path` configuration parameter depending on `dia` location.
# Uses the result of the `find_package(Doxypress)` call.
##############################################################################
function(_doxypress_set_dia_path _out_var)
    if (TARGET Doxypress::dia)
        get_target_property(DIA_PATH Doxypress::dia IMPORTED_LOCATION)
        set(${_out_var} "${DIA_PATH}" PARENT_SCOPE)
        _doxypress_action("dot.dia-path" setter "${DIA_PATH}")
    endif ()
endfunction()

##############################################################################
# @brief Sets `warning format` configuration parameter depending on the build
# tool.
##############################################################################
function(_doxypress_set_warn_format _out_var)
    if ("${CMAKE_BUILD_TOOL}" MATCHES "(msdev|devenv)")
        set(${_out_var} "$file($line) : $text" PARENT_SCOPE)
        _doxypress_action("messages.warn-format" setter "$file($line) : $text")
    else ()
        set(${_out_var} "$file:$line: $text" PARENT_SCOPE)
        _doxypress_action("messages.warn-format" setter "$file:$line: $text")
    endif ()
endfunction()

##############################################################################
## @brief Sets `output-latex.makeindex-cmd-name` to the value of
## `MAKEINDEX_COMPILER` set by `find_package(LATEX)`.
##############################################################################
function(_doxypress_set_makeindex_cmd_name _out_var)
    if (NOT "${MAKEINDEX_COMPILER}" STREQUAL "MAKEINDEX_COMPILER-NOTFOUND")
        set(${_out_var} "${MAKEINDEX_COMPILER}" PARENT_SCOPE)
        _doxypress_action("output-latex.makeindex-cmd-name"
                setter "${MAKEINDEX_COMPILER}")
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Sets `dot path` configuration parameter depending on `dot` location.
# Uses the result of the `find_package(Doxypress)` call.
##############################################################################
function(_doxypress_set_dot_path _out_var)
    if (TARGET Doxypress::dot)
        get_target_property(DOT_PATH Doxypress::dot IMPORTED_LOCATION)
        set(${_out_var} "${DOT_PATH}" PARENT_SCOPE)
        _doxypress_action("dot.dot-path" setter "${DOT_PATH}")
    endif ()
endfunction()

##############################################################################
# @brief Walks through directory paths in a given list and updates relative
# ones by prepending `CMAKE_CURRENT_SOURCE_DIR`. Does nothing
# to absolute directory paths.
##############################################################################
function(_doxypress_update_input_source _sources _out_var)
    set(_inputs "")
    # _doxypress_log(DEBUG "input sources before update: ${_sources}")
    if (_sources)
        foreach (_path ${_sources})
            if (NOT IS_ABSOLUTE ${_path})
                get_filename_component(_path ${CMAKE_CURRENT_SOURCE_DIR}/${_path}
                        ABSOLUTE)
            endif ()
            list(APPEND _inputs ${_path})
        endforeach ()
    else()
        TPA_get("INPUT_TARGET" _input_target)
        if (TARGET ${_input_target})
            get_target_property(_inputs "${_input_target}"
                    INTERFACE_INCLUDE_DIRECTORIES)
            _doxypress_log(DEBUG
                    "input sources from ${_input_target}: ${_inputs}")
        endif ()
    endif()
    # _doxypress_log(DEBUG "input sources after update: ${_inputs}")
    _doxypress_action("input.input-source" "updater" "${_inputs}")
    set(${_out_var} "${_inputs}" PARENT_SCOPE)
endfunction()

##############################################################################
# @brief Updates a list of given directories:
# * a relative directory is turned into an absolute one, prepending
# `CMAKE_CURRENT_SOURCE_DIR`;
# * an absolute directory stays unchanged.
##############################################################################
function(_doxypress_update_example_source _value _out_var)
    if (_value)
        set(_result "")
        foreach(_dir ${_value})
            if (NOT IS_ABSOLUTE "${_dir}")
                get_filename_component(_dir
                        "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}"
                        ABSOLUTE)
            endif ()
            list(APPEND _result "${_dir}")
        endforeach()
        _doxypress_action("input.example-source" "updater" "${_result}")
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Updates a relative directory path by prepending
# `CMAKE_CURRENT_BINARY_DIR`. Does nothing to absolute directory path.
##############################################################################
function(_doxypress_update_output_dir _value _out_var)
    if (_value)
        if (NOT IS_ABSOLUTE "${_value}")
            get_filename_component(_dir
                    "${CMAKE_CURRENT_BINARY_DIR}/${_value}"
                    ABSOLUTE)
            set(${_out_var} "${_dir}" PARENT_SCOPE)
            _doxypress_action("general.output-dir" "updater" "${_dir}")
        endif ()
    endif ()
endfunction()

##############################################################################
# Sets `have dot` configuration flag depending on `dot` presence. Uses
# the result of the `find_package(Doxypress)` call.
##############################################################################
function(_doxypress_set_have_dot _out_var)
    if (TARGET Doxypress::dot)
        set(${_out_var} true PARENT_SCOPE)
        # todo
        #set(DOXYGEN_DOT_MULTI_TARGETS true)
        _doxypress_action("dot.have-dot" "setter" true)
    else ()
        set(${_out_var} false PARENT_SCOPE)
        _doxypress_action("dot.have-dot" "setter" false)
    endif ()
endfunction()

function(_doxypress_set_input_target _out_var)
    if (TARGET ${PROJECT_NAME})
        set(${_out_var} ${PROJECT_NAME} PARENT_SCOPE)
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif()
endfunction()

##############################################################################
# @brief Sets `example directory` configuration parameter by searching one of
# `example`, `examples` directories in the current project's root directory.
##############################################################################
function(_doxypress_set_example_source _out_var)
    _doxypress_find_directory(
            example_path
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "example;examples"
    )
    set(${_out_var} "${example_path}" PARENT_SCOPE)
    _doxypress_action("input.example-source" "setter" "${example_path}")
endfunction()

##############################################################################
# @brief Searches for a file with the name from the list `FILES` in
# the directories from the list `DIRS`; sets the variable `out_var`
# to contain the full file name if found. The first matching file name
# is returned, the other ones are ignored.
# @param[out] _out_var output variable
# @param[in] _base_dir directory to search
# @param[in] _names sub-directories to find
##############################################################################
function(_doxypress_find_directory _out_var _base_dir _names)
    set(_result "")
    foreach (_name ${_names})
        if (IS_DIRECTORY ${_base_dir}/${_name})
            _doxypress_log(DEBUG "Found directory ${_base_dir}/${_name}")
            list(APPEND _result ${_base_dir}/${_name})
        endif ()
    endforeach ()
    set(${_out_var} "${_result}" PARENT_SCOPE)
endfunction()

function(_doxypress_action _property _action _value)
    set(_message "")
    if ("${_value}" STREQUAL "")
        set(_value "<<empty>>")
    endif()
    if (${_action} STREQUAL setter)
        set(_message "[setter] ${_value}")
    elseif(${_action} STREQUAL updater)
        set(_message "[updater] ${_value}")
    elseif(${_action} STREQUAL default)
        set(_message "[default] ${_value}")
    elseif(${_action} STREQUAL source)
        set(_message "[source] ${_value}")
    elseif(${_action} STREQUAL input)
        set(_message "[input] ${_value}")
    elseif(${_action} STREQUAL merge)
        set(_message "[merged] ${_value}")
    endif()
    TPA_get("histories" _histories)
    TPA_append("history.${_property}" "${_message}")

    if (NOT ${_property} IN_LIST _histories)
        TPA_append("histories" ${_property})
    endif()
endfunction()