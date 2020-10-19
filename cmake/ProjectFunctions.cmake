##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# Project functions
# -----------------
#
# This module contains non-public functions that are a part of the
# :ref:`doxypress_add_docs` implementation.
##############################################################################

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init
#
# .. code-block:: cmake
#
#    _doxypress_params_init()
#
# Initializes parsing context. Changes made by this function in the current
# scope can be reverted by :cmake:command:`TPA_clear_scope`.
##############################################################################
function(_doxypress_params_init)
    # define acceptable input parameters
    _doxypress_params_init_inputs()
    # define properties that are processed by the chain of handlers
    # `input` -> `json` -> `setter` -> `updater` -> `default`
    _doxypress_params_init_properties()
    # define properties that are set to a constant value
    _doxypress_params_init_overrides()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_inputs
#
# .. code-block:: cmake
#
#    _doxypress_params_init_inputs()
#
# Initializes input parameters that should be parsed by
# :ref:`doxypress_add_docs`.
##############################################################################
function(_doxypress_params_init_inputs)
    _doxypress_input_string(
            PROJECT_FILE
            UPDATER "update_project_file"
            DEFAULT "${_doxypress_dir}/DoxypressCMake.json"
    )
    _doxypress_input_string(INPUT_TARGET SETTER "set_input_target")
    _doxypress_input_string(TARGET_NAME SETTER "set_target_name")
    _doxypress_input_string(INSTALL_COMPONENT DEFAULT docs)
    _doxypress_input_option(GENERATE_PDF DEFAULT false)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_overrides
#
# .. code-block:: cmake
#
#    _doxypress_params_init_overrides()
#
# Initializes the default set of :ref:`overrides<overrides-reference-label>`.
##############################################################################
function(_doxypress_params_init_overrides)
    doxypress_add_override("project.project-brief" "${PROJECT_DESCRIPTION}")
    doxypress_add_override("project.project-name" "${PROJECT_NAME}")
    doxypress_add_override("project.project-version" "${PROJECT_VERSION}")
    doxypress_add_override("output-latex.latex-batch-mode" true)
    doxypress_add_override("output-latex.latex-hyper-pdf" true)
    doxypress_add_override("output-latex.latex-output" "latex")
    doxypress_add_override("output-latex.latex-pdf" true)
    doxypress_add_override("output-html.html-output" "html")
    doxypress_add_override("output-html.html-file-extension" ".html")
    doxypress_add_override("output-xml.xml-output" "xml")
    doxypress_add_override("input.input-recursive" true)
    doxypress_add_override("input.example-recursive" true)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_inputs
#
# .. code-block:: cmake
#
#    _doxypress_params_init_overrides()
#
# Initializes properties that are processed by the chain of handlers:
#   ``input`` -> ``json`` -> ``setter`` -> ``updater` -> ``default`
##############################################################################
function(_doxypress_params_init_properties)
    _doxypress_property_add("messages.quiet" DEFAULT true)
    _doxypress_property_add("messages.warnings" DEFAULT true)
    _doxypress_property_add("dot.have-dot" SETTER "set_have_dot" OVERWRITE)
    _doxypress_property_add("dot.dot-path" SETTER "set_dot_path" OVERWRITE)
    _doxypress_property_add("dot.dia-path" SETTER "set_dia_path" OVERWRITE)
    _doxypress_property_add("output-xml.generate-xml"
            INPUT_OPTION GENERATE_XML
            DEFAULT false)
    _doxypress_property_add("output-latex.generate-latex"
            INPUT_OPTION GENERATE_LATEX
            UPDATER "update_generate_latex"
            DEFAULT false)
    _doxypress_property_add("output-html.generate-html"
            INPUT_STRING GENERATE_HTML
            DEFAULT true)
    _doxypress_property_add("general.output-dir"
            INPUT_STRING OUTPUT_DIRECTORY
            UPDATER "update_output_dir"
            DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/doxypress-generated")
    _doxypress_property_add(${_DOXYPRESS_INPUT_SOURCE}
            INPUT_LIST INPUTS
            UPDATER "update_input_source")
    _doxypress_property_add("input.example-source"
            INPUT_LIST EXAMPLE_DIRECTORIES
            SETTER "set_example_source"
            UPDATER "update_example_source")
    _doxypress_property_add("messages.warn-format"
            SETTER "set_warn_format" OVERWRITE)
    _doxypress_property_add("output-latex.makeindex-cmd-name"
            SETTER "set_makeindex_cmd_name" OVERWRITE)
    _doxypress_property_add("output-latex.latex-cmd-name"
            SETTER "set_latex_cmd_name" OVERWRITE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_project_update
#
# .. code-block:: cmake
#
#   _doxypress_project_update(_input_project_file_name _out_var)
#
# Loads a given project file ``_input_project_file_name``, applies update logic
# that was previously defined by :cmake:command:`_doxypress_params_init`
# and saves the updated file. The name of the updated file is written into
# the output variable ``_out_var``.
##############################################################################
macro(_doxypress_project_update _input_project_file_name _out_var)
    _doxypress_project_load(${_input_project_file_name})

    TPA_get("${_DOXYPRESS_JSON_PATHS_KEY}" _updatable_paths)

    foreach (_path ${_updatable_paths})
        _doxypress_update_path(${_path})
    endforeach()

    # create name for the processed project file
    _doxypress_output_project_file_name(
            ${_input_project_file_name}
            _output_project_file_name)

    # save processed project file
    _doxypress_project_save("${_output_project_file_name}")
    set(${_out_var} "${_output_project_file_name}")
endmacro()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_project_load
#
# .. code-block:: cmake
#
#    _doxypress_project_load(_project_file_name)
#
# Loads a given project file ``_project_file_name`` into the current
# :ref:`TPA scope`. The name of every resulting property is prefixed with
# ``doxypress.``.
##############################################################################
function(_doxypress_project_load _project_file_name)
    _doxypress_log(INFO "Loading project template ${_project_file_name}...")
    file(READ "${_project_file_name}" _contents)
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
#    _doxypress_project_save(_project_file_name)
#
# Saves a parsed JSON document into a given file ``_project_file_name``.
# The JSON tree is taken from the current TPA scope. Any existing file with
# the same name is overwritten.
##############################################################################
function(_doxypress_project_save _project_file_name)
    _doxypress_assert_not_empty("${_project_file_name}")
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)

    _JSON_serialize("${_variables}" _json)
    _doxypress_log(INFO "Saving project file ${_project_file_name}...")
    file(WRITE "${_project_file_name}" ${_json})
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_get
#
# .. code-block:: cmake
#
#    # same as _JSON_get("doxypress.${_path}" _out_var)
#    _doxypress_get(_path _out_var)
#
##############################################################################
function(_doxypress_get _path _out_var)
    _JSON_get("doxypress.${_path}" _json_value)
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_set
#
# .. code-block:: cmake
#
#    # same as _JSON_set("doxypress.${_path}" _value)
#    _doxypress_set(_path _value)
##############################################################################
function(_doxypress_set _property _value)
    _JSON_set(doxypress.${_property} "${_value}")
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_call
#
# .. code-block:: cmake
#
#    _doxypress_call(_id _arg1)
#
# Calls a function or a macro given its name ``_id``. Writes actual call code
# into a temporary file, which is then included. ``ARGN`` is also passed.
##############################################################################
macro(_doxypress_call _id _arg1)
    if (NOT COMMAND ${_id})
        message(FATAL_ERROR "Unsupported function/macro \"${_id}\"")
    else ()
        set(_helper "${CMAKE_CURRENT_BINARY_DIR}/helpers/macro_helper_${_id}.cmake")
        file(WRITE "${_helper}" "${_id}(\"${_arg1}\" ${ARGN})\n")
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
#   _doxypress_find_directory(_base_dir _names _out_var)
#
# Searches for a directory with a name from ``_names``, starting from
# ``_base_dir``. Sets the output variable ``_out_var`` to contain absolute
# path of every found directory.
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

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_output_project_file_name
#
# ..  code-block:: cmake
#
#   _doxypress_output_project_file_name(_project_file_name _out_var)
#
# Generates an output project file's name, given the input name.
# Replaces th path to input project file ``_project_file_name`` by
# *CMAKE_CURRENT_BINARY_DIR* while leaving the file name unchanged.
##############################################################################
function(_doxypress_output_project_file_name _project_file_name _out_var)
    _doxypress_assert_not_empty("${_project_file_name}")
    get_filename_component(_name "${_project_file_name}" NAME)
    set(${_out_var} ${CMAKE_CURRENT_BINARY_DIR}/${_name} PARENT_SCOPE)
endfunction()
