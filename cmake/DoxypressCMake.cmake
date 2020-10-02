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
    doxypress_params_init()

    # parse input parameters that are not in the JSON project file
    doxypress_params_parse(${ARGN})
    TPA_get(PROJECT_FILE _project_file)
    # now we have the JSON template to parse
    doxypress_project_load(${_project_file})
    # update JSON properties
    doxypress_project_update()
    # save updated JSON
    doxypress_project_save("${_project_file}")

    doxypress_create_targets("${_project_file}")
    TPA_get(INSTALL_COMPONENT _install_component)

    if (_install_component)
        # doxypress_log(INFO "CMAKE_INSTALL_DOCDIR = ${CMAKE_INSTALL_DOCDIR}")
        doxypress_install_docs("${CMAKE_INSTALL_DOCDIR}" ${_install_component})
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
function(doxypress_project_load _file_name)
    doxypress_log(INFO "loading ${_file_name}...")
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
function(doxypress_project_save _file_name)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)

    JSON_serialize("${_variables}" _json)
    file(WRITE "${_file_name}" ${_json})
endfunction()

##############################################################################
# @brief Prepares argument parsing context.
##############################################################################
function(doxypress_params_init)
    # TPA_create_scope(${_doxypress_cmake_uuid} _arguments_target)
    doxypress_param_string(PROJECT_FILE
            UPDATER "update_doxyfile"
            DEFAULT "${doxypress_dir}/DoxypressCMake.json")
    doxypress_param_string(INPUT_TARGET SETTER "set_input_target")
    doxypress_param_string(INSTALL_COMPONENT)
    doxypress_param_option(GENERATE_PDF DEFAULT false)

    doxypress_json_property(
            "output-xml.generate-xml"
            INPUT_OPTION GENERATE_XML
            DEFAULT false)
    doxypress_json_property(
            "output-latex.generate-latex"
            INPUT_OPTION GENERATE_LATEX
            DEFAULT false)
    doxypress_json_property(
            "output-html.generate-html"
            INPUT_STRING GENERATE_HTML
            DEFAULT true)

    doxypress_json_property("general.output-dir"
            INPUT_STRING OUTPUT_DIRECTORY
            UPDATER "update_output_dir"
            DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/doxypress-generated")

    doxypress_json_property("input.input-source"
            INPUT_LIST INPUT_DIRECTORIES
            UPDATER "update_input_source")

    doxypress_json_property("input.example-source"
           INPUT_LIST EXAMPLE_DIRECTORIES
           SETTER "set_example_source"
           UPDATER "update_example_source")

    doxypress_json_property("dot.have-dot" SETTER "set_have_dot" OVERWRITE)
    doxypress_json_property("dot.dot-path" SETTER "set_dot_path" OVERWRITE)
    doxypress_json_property("dot.dia-path" SETTER "set_dia_path" OVERWRITE)
    doxypress_json_property("messages.warn-format"
            SETTER "set_warn_format"
            OVERWRITE)
    doxypress_json_property("output-latex.makeindex-cmd-name"
            SETTER "set_makeindex_cmd_name"
            OVERWRITE)
    doxypress_json_property("output-latex.latex-cmd-name"
            SETTER "set_latex_cmd_name"
            OVERWRITE)

    doxypress_json_property("messages.quiet" DEFAULT true)
    doxypress_json_property("messages.warnings" DEFAULT true)

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
    # set("messages.quiet" true PARENT_SCOPE)
    # set("messages.warnings" true PARENT_SCOPE)
    set("input.input-recursive" true PARENT_SCOPE)
    set("input.example-recursive" true PARENT_SCOPE)
endfunction()

macro(doxypress_project_update)
    TPA_get(GENERATE_LATEX _generate_latex)
    if ("${_generate_latex}" AND NOT DEFINED LATEX_FOUND)
        doxypress_log(INFO "LaTex generation requested, importing LATEX...")
        find_package(LATEX COMPONENTS PDFLATEX)
    endif()

    TPA_get("${_DOXYPRESS_JSON_PATHS_KEY}" _properties)

    foreach (_property ${_properties})
        doxypress_json_update_property(${_property})
    endforeach ()
endmacro()

function(doxypress_cut_prefix _var _out_var)
    string(FIND ${_var} "." _ind)
    math(EXPR _ind "${_ind} + 1")
    string(SUBSTRING ${_var} ${_ind} -1 _cut_var)
    set(${_out_var} ${_cut_var} PARENT_SCOPE)
endfunction()


function(doxypress_json_update_property _property)
    # doxypress_cut_prefix(${_property} xxx)
    TPA_get(${_property}_UPDATER _updater)
    doxypress_log(DEBUG "updater for ${_property} is ${_updater}")
    TPA_get(${_property}_SETTER _setter)
    doxypress_log(DEBUG "setter for ${_property} is ${_setter}")
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
    endif ()
    set(_value "${_input_value}")

    doxypress_log(DEBUG "[json_update_property] ${_property}")

    if ("${_value}" STREQUAL "")
        JSON_get(doxypress.${_property} _value)
        doxypress_log(DEBUG "[json_update_property] value in JSON = ${_value}")
    endif ()
    if (_value STREQUAL "" OR _overwrite)
        if (_setter)
            doxypress_log(DEBUG "call setter ${_setter}")
            doxypress_call(doxypress_${_setter} _value)
        endif ()
        if (_updater)
            doxypress_log(DEBUG "call updater ${_updater}")
            doxypress_call(doxypress_${_updater} "${_value}" _value)
        endif ()
        if (_value STREQUAL "")
            # if no default, _value is left empty
            if (NOT _default STREQUAL "")
                set(_value "${_default}")
                doxypress_log(INFO "[default] ${_property} = ${_default}")
            endif ()
        else ()
            doxypress_log(INFO "[setter+updater] ${_property} = ${_value}")
        endif ()
    else ()
        # if it's an array merge with input if any
        TPA_get(doxypress.${_property} _json_value)
        # doxypress_log(DEBUG "[json_update_property] TPA_get -> ${_json_value}")
        if (NOT _input_value STREQUAL "" AND "${_json_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
            JSON_get(doxypress.${_property} _json_value)
            foreach(_val ${_value})
                list(APPEND _json_value "${_val}")
            endforeach()
            set(_value ${_json_value})
        endif()

        if (_updater)
            doxypress_log(DEBUG "[json_update_property] before updater ${_property} = ${_value}")
            doxypress_call(doxypress_${_updater} "${_value}" _value)
        endif ()
        doxypress_log(INFO "[json] ${_property} = ${_value}")
    endif ()

    JSON_set(doxypress.${_property} "${_value}")
    if (_input_arg_name)
        TPA_set(${_input_arg_name} "${_value}")
    endif ()
endfunction()

##############################################################################
## @brief Sets `output-latex.latex-cmd-name` to the value of
## `PDFLATEX_COMPILER` set by `find_package(LATEX)`.
##############################################################################
function(doxypress_set_latex_cmd_name _out_var)
    if (DEFINED PDFLATEX_COMPILER)
        set(${_out_var} "${PDFLATEX_COMPILER}" PARENT_SCOPE)
        doxypress_log(INFO "latex-cmd-name = ${PDFLATEX_COMPILER}")
    endif ()
endfunction()

function(doxypress_update_doxyfile _doxyfile _out_var)
    set(_result "")
    if (NOT IS_ABSOLUTE ${_doxyfile})
        get_filename_component(_result
                ${CMAKE_CURRENT_SOURCE_DIR}/${_doxyfile} ABSOLUTE)
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

function(doxypress_set_input_target _out_var)
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
function(doxypress_set_dia_path _out_var)
    if (TARGET Doxypress::dia)
        get_target_property(DIA_PATH Doxypress::dia IMPORTED_LOCATION)
        set(${_out_var} "${DIA_PATH}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Sets `warning format` configuration parameter depending on the build
# tool.
##############################################################################
function(doxypress_set_warn_format _out_var)
    if ("${CMAKE_BUILD_TOOL}" MATCHES "(msdev|devenv)")
        set(${_out_var} "$file($line) : $text" PARENT_SCOPE)
    else ()
        set(${_out_var} "$file:$line: $text" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
## @brief Sets `output-latex.makeindex-cmd-name` to the value of
## `MAKEINDEX_COMPILER` set by `find_package(LATEX)`.
##############################################################################
function(doxypress_set_makeindex_cmd_name _out_var)
    if (DEFINED MAKEINDEX_COMPILER)
        set(${_out_var} "${MAKEINDEX_COMPILER}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Sets `dot path` configuration parameter depending on `dot` location.
# Uses the result of the `find_package(Doxypress)` call.
##############################################################################
function(doxypress_set_dot_path _out_var)
    if (TARGET Doxypress::dot)
        get_target_property(DOT_PATH Doxypress::dot IMPORTED_LOCATION)
        set(${_out_var} "${DOT_PATH}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Walks through directory paths in a given list and updates relative
# ones by prepending `CMAKE_CURRENT_SOURCE_DIR`. Does nothing
# to absolute directory paths.
##############################################################################
function(doxypress_update_input_source _sources _out_var)
    set(_inputs "")
    doxypress_log(DEBUG "input sources before update: ${_sources}")
    if (_sources)
        foreach (_dir ${_sources})
            if (NOT IS_ABSOLUTE ${_dir})
                get_filename_component(_dir ${CMAKE_CURRENT_SOURCE_DIR}/${_dir}
                        ABSOLUTE)
            endif ()
            list(APPEND _inputs ${_dir})
        endforeach ()
    else()
        TPA_get("INPUT_TARGET" _input_target)
        if (TARGET ${_input_target})
            get_target_property(_inputs "${_input_target}"
                    INTERFACE_INCLUDE_DIRECTORIES)
        endif ()
    endif()
    doxypress_log(DEBUG "input sources after update: ${_inputs}")
    set(${_out_var} "${_inputs}" PARENT_SCOPE)
endfunction()

##############################################################################
# @brief Updates a list of given directories:
# * a relative directory is turned into an absolute one, prepending
# `CMAKE_CURRENT_SOURCE_DIR`;
# * an absolute directory stays unchanged.
##############################################################################
function(doxypress_update_example_source _value _out_var)
    if (_value)
        set(_result "")
        #set(_value ${_value})
        foreach(_dir ${_value})
            doxypress_log(DEBUG "updating example dir ${_dir}...")
            if (NOT IS_ABSOLUTE "${_dir}")
                get_filename_component(_dir
                        "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}"
                        ABSOLUTE)
            endif ()
            list(APPEND _result "${_dir}")
        endforeach()
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Updates a relative directory path by prepending
# `CMAKE_CURRENT_BINARY_DIR`. Does nothing to absolute directory path.
##############################################################################
function(doxypress_update_output_dir _value _out_var)
    doxypress_log(DEBUG "[update_output_dir] output directory is `${_value}`")
    if (_value)
        if (NOT IS_ABSOLUTE "${_value}")
            get_filename_component(_dir
                    "${CMAKE_CURRENT_BINARY_DIR}/${_value}"
                    ABSOLUTE)
            set(${_out_var} "${_dir}" PARENT_SCOPE)
            doxypress_log(DEBUG "output directory is updated to `${_dir}`")
        endif ()
    endif ()
endfunction()

##############################################################################
# Sets `have dot` configuration flag depending on `dot` presence. Uses
# the result of the `find_package(Doxypress)` call.
##############################################################################
function(doxypress_set_have_dot _out_var)
    if (TARGET Doxypress::dot)
        set(${_out_var} true PARENT_SCOPE)
        # todo
        #set(DOXYGEN_DOT_MULTI_TARGETS true)
    else ()
        set(${_out_var} false PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Sets `example directory` configuration parameter by searching one of
# `example`, `examples` directories in the current project's root directory.
##############################################################################
function(doxypress_set_example_source _out_var)
    doxypress_find_directory(
            example_path
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "example;examples"
    )
    set(${_out_var} "${example_path}" PARENT_SCOPE)
    doxypress_log(DEBUG "EXAMPLE_DIRECTORIES is set to `${example_path}`")
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
function(doxypress_find_directory _out_var _base_dir _names)
    set(_result "")
    foreach (_name ${_names})
        if (IS_DIRECTORY ${_base_dir}/${_name})
            doxypress_log(DEBUG "Found directory ${_base_dir}/${_name}")
            list(APPEND _result ${_base_dir}/${_name})
        endif ()
    endforeach ()
    set(${_out_var} "${_result}" PARENT_SCOPE)
endfunction()
