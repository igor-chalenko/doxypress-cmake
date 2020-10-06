##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

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

set(_DOXYPRESS_LATEX_CMD_NAME "output-latex.latex-cmd-name")
set(_DOXYPRESS_MAKEINDEX_CMD_NAME "output-latex.makeindex-cmd-name")
set(_DOXYPRESS_EXAMPLE_SOURCE "input.example-source")
set(_DOXYPRESS_INPUT_SOURCE "input.input-source")

include(${doxypress_dir}/DoxypressCommon.cmake)
include(${doxypress_dir}/TargetPropertyAccess.cmake)
include(${doxypress_dir}/JSONFunctions.cmake)
include(${doxypress_dir}/Setters.cmake)

##############################################################################
#.rst:
# DoxypressCMake
# --------------
#
# .. cmake:command:: doxypress_add_docs
#
# .. code-block:: cmake
#
#    doxypress_add_docs([PROJECT_FILE] <name>
#                       [INPUT_TARGET] <name>
#                       [EXAMPLES] <directories>
#                       [INPUTS] <files and directories>
#                       [INSTALL_COMPONENT] <name>
#                       [GENERATE_HTML]
#                       [GENERATE_LATEX]
#                       [GENERATE_PDF]
#                       [GENERATE_XML]
#                       [OUTPUT_DIRECTORY] <directory>)
#
# Generates documentation using `Doxypress`. Performs the following tasks:
#
# * Creates a target ``prefix.doxypress`` to run `Doxypress`; here ``prefix``
#   is the value of ``INPUT_TARGET`` if one was given, or ``PROJECT_NAME``
#   otherwise.
# * Creates additional targets to open the generated documentation
#   (``index.html``, ``refman.tex`` or ``refman.pdf``). An application that is
#   configured to open the files of corresponding type is used.
# * Adds the generated files to the ``install`` target, if a non-empty value
#   of ``INSTALL_COMPONENT`` was given.
#
# ----------------
# Input parameters
# ----------------
# **PROJECT_FILE**
#    JSON project file that `Doxypress` uses as input. Antwerp will read
#    this file during CMake configuration phase, update it accordingly, write
#    the updated file back, and use the result as actual configuration. See
#    :ref:`Algorithm description` for a detailed description of what the package
#    does.
#
#    Defaults to `DoxypressAddDocs.json`, provided with the package.
#
# .. _inputs-reference-label:
#
# **INPUTS**
#    A list of files and directories to be processed by `Doxypress`; takes
#    priority over `INPUT_TARGET`.
#
# **INPUT_TARGET**
#    If defined (correctly), this target's property
#    `INTERFACE_INCLUDE_DIRECTORIES` determines the input sources in
#    the generated project file. If :ref:`INPUTS<inputs-reference-label>` are
#    not empty, this parameter is ignored.
#
# **INSTALL_COMPONENT**
#    If specified, an installation command for generated docs will be added to
#    the `install` target; the input parameter is used as the component name for
#    the generated files.
#
# **OUTPUT_DIRECTORY**
#     The base directory for all the generated documentation files.
#     Default is `doxypress-generated`.
#
# ----------------------
# Project file overrides
# ----------------------
#
# In addition to the properties handled by :cmake:command:`doxypress_add_docs`,
# it's possible to change other properties as well by using appropriate
# ``set(property value)`` commands. This could be useful if you use the default
# project file and need to change pre-defined settings, or you need to update
# a certain property based on some custom logic. In order to do so, set
# a `CMake` variable with a name that corresponds to the JSON path of a property
# you need to updated. For example, the following command will instruct
# `Doxypress` to inline source code into the generated documentation:
#
# .. code-block:: cmake
#
#   set(source.inline-source true)
#
# :cmake:command:`doxypress_add_docs` uses the same mechanism to provide
# defaults that are meaningful in the context of `CMake` processing
# (and in general). The following properties are always set to a constant value:
#
# * ``output-html.html-output`` = ``html``
# * ``output-latex.latex-output`` = ``latex``
# * ``output-xml.xml-output`` = ``xml``
#
#    The author sees little value in customizing these since the base output
#    directory is customizable.
#
# * ``project.project-name`` = ``${PROJECT_NAME}``
# * ``project.project-version`` = ``${PROJECT_VERSION}``
# * ``project.project-brief`` = ``${PROJECT_DESCRIPTION}``
#
#    These are specified in `CMakeLists.txt`; one doesn't have to maintain
#    project nomenclature more times than needed.
#
# * ``input.input-recursive`` = ``true``
# * ``input.example-recursive`` = ``true``
#
#   The default template generated by `Doxypress` sets these to ``false``,
#   mimicking the behavior of `Doxygen`. The author believes the value of
#   ``true`` is more appropriate, given the number of ``exclude`` options that
#   allow achieving the same result. One has to be able to freely
#   expand/refactor the existing source tree without worrying about breaking
#   documentation.
#
# * ``dot.have-dot``
# * ``dot.dot-path``
# * ``dot.dia-path``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``output-latex.latex-cmd-name`` = ``${PDFLATEX_COMPILER}``
# * ``output-latex.make-index-cmd-name`` = ``${MAKEINDEX_COMPILER}``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``output-latex.latex-pdf`` = ``true``
#
#   If `pdflatex` is installed, it will be used to get "a better quality PDF",
#   as stated in `Doxypress` documentation (and originally in `Doxygen`'s).
#
# * ``output-latex.latex-batch-mode`` = ``true``
#
#   LaTex batch mode enables non-interactive processing, which is exactly what
#   the package does.
#
# * ``output-latex.latex-hyper-pdf`` = ``true``
#
#   Hyperlink generation requires running ``pdflatex`` several times, but these
#   days it's not that expensive, while the value of hyperlinks is great.
#
# .. note::
#   If `.tex` generation was requested, but LaTex installation was not found
#   after the call to
#
#   .. code-block::
#
#     find_package(LATEX),
#
#   then the `.tex` generation is disabled and the properties
#   ``output-latex.latex-cmd-name`` and ``output-latex.make-index-cmd-name`` are
#   unset.
#
# * ``messages.warn-format``
#
#   This is configured separately for MS Visual Studio; other build tools
#   use a default value.
#
# ---------
# Algorithm
# ---------
#
# * 1. The input JSON configuration is parsed into a flat list of variables as
#   described in the documentation of `sbeParseJson` from json-cmake_;
# * 2. Some of these variables get a new value. The set of JSON properties
#   to update is defined by :cmake:command:`_doxypress_params_init_properties`.
#   Each property is assigned a set of handlers, described in the documentation
#   for :cmake:command:`_doxypress_json_property`. Then, the following logic
#   is applied for each individual property:
#   * the `current value` is assigned an empty string;
#   * the input argument, if it was specified, becomes the new current value;
#   * ``SETTER`` is invoked, if the current property value is empty;
#   * ``UPDATER`` is invoked, if the current property value is NOT empty;
#   * the current value is set to the value of ``DEFAULT``, if the current
#     property value is still empty).
# * 3. The list of variables is re-assembled back into a new JSON document,
#   which is then written to a file that becomes the final Doxypress
#   configuration. Property overrides are applied during serialization phase.
#
# .. _json-cmake: https://github.com/sbellus/json-cmake
##############################################################################
function(doxypress_add_docs)
    # initialize parameter/property descriptions
    _doxypress_params_init()
    # parse input arguments
    _doxypress_params_parse(${ARGN})
    # get the project file name
    TPA_get(PROJECT_FILE _input_project_file)
    # update project file
    _doxypress_project_update("${_input_project_file}" _output_project_file)
    # create target(s)
    _doxypress_create_targets("${_input_project_file}" "${_output_project_file}")

    TPA_get(INSTALL_COMPONENT _install_component)
    if (_install_component)
        include(GNUInstallDirs)
        _doxypress_install_docs("${CMAKE_INSTALL_DOCDIR}" ${_install_component})
    endif ()

    # clear up the TPA scope created by this function
    TPA_clear_scope()
endfunction()

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

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init
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
# Initializes input parameters that should be accepted by
# :cmake:command:`doxypress_add_docs`.
##############################################################################
function(_doxypress_params_init_inputs)
    _doxypress_param_string(PROJECT_FILE
            UPDATER "update_project_file"
            DEFAULT "${doxypress_dir}/DoxypressCMake.json")
    _doxypress_param_string(INPUT_TARGET SETTER "set_input_target")
    _doxypress_param_string(INSTALL_COMPONENT)
    _doxypress_param_option(GENERATE_PDF DEFAULT false)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_overrides
#
# Initializes the default set of :ref:`overrides<Project file overrides>`.
##############################################################################
function(_doxypress_params_init_overrides)
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

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_inputs
#
# Initializes properties that are processed by the chain of handlers:
#
# ..code-block::
#
#   `input` -> `json` -> `setter` -> `updater` -> `default`
#
##############################################################################
function(_doxypress_params_init_properties)
    _doxypress_json_property("messages.quiet" DEFAULT true)
    _doxypress_json_property("messages.warnings" DEFAULT true)
    _doxypress_json_property("dot.have-dot" SETTER "set_have_dot" OVERWRITE)
    _doxypress_json_property("dot.dot-path" SETTER "set_dot_path" OVERWRITE)
    _doxypress_json_property("dot.dia-path" SETTER "set_dia_path" OVERWRITE)
    _doxypress_json_property("output-xml.generate-xml"
            INPUT_OPTION GENERATE_XML
            DEFAULT false)
    _doxypress_json_property("output-latex.generate-latex"
            INPUT_OPTION GENERATE_LATEX
            DEFAULT false)
    _doxypress_json_property("output-html.generate-html"
            INPUT_STRING GENERATE_HTML
            DEFAULT true)
    _doxypress_json_property("general.output-dir"
            INPUT_STRING OUTPUT_DIRECTORY
            UPDATER "update_output_dir"
            DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/doxypress-generated")
    _doxypress_json_property(${_DOXYPRESS_INPUT_SOURCE}
            INPUT_LIST INPUTS
            UPDATER "update_input_source")
    _doxypress_json_property(${_DOXYPRESS_EXAMPLE_SOURCE}
            INPUT_LIST EXAMPLE_DIRECTORIES
            SETTER "set_example_source"
            UPDATER "update_example_source")
    _doxypress_json_property("messages.warn-format"
            SETTER "set_warn_format"
            OVERWRITE)
    _doxypress_json_property(${_DOXYPRESS_MAKEINDEX_CMD_NAME}
            SETTER "set_makeindex_cmd_name"
            OVERWRITE)
    _doxypress_json_property(${_DOXYPRESS_LATEX_CMD_NAME}
            SETTER "set_latex_cmd_name"
            OVERWRITE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_project_update
#
# ..code-block::
#
#   _doxypress_project_update(<project file name> <output variable>)
#
# Loads a given project file, applies update logic that was previously defined
# by :cmake:command:`_doxypress_params_init`, and saves the updated file.
# The name of the updated file is written into the output variable.
##############################################################################
macro(_doxypress_project_update _project_file _out_var)
    _doxypress_project_load(${_project_file})

    TPA_get(GENERATE_LATEX _generate_latex)
    if ("${_generate_latex}" AND NOT DEFINED LATEX_FOUND)
        _doxypress_log(INFO "LaTex generation requested, importing LATEX...")
        find_package(LATEX OPTIONAL_COMPONENTS MAKEINDEX PDFLATEX)
        if (NOT LATEX_FOUND)
            _JSON_set("doxypress.output-latex.generate-latex" false)
            _doxypress_log(WARN "LATEX was not found; skip LaTex generation.")
        endif()
    endif()

    TPA_get("${_DOXYPRESS_JSON_PATHS_KEY}" _properties)

    foreach (_property ${_properties})
        _doxypress_json_update_property(${_property})
    endforeach ()

    # create name for the processed project file
    _doxypress_project_generated_name(${_project_file} _file_name)
    # save processed project file
    _doxypress_project_save("${_file_name}")
    set(${_out_var} "${_file_name}")
endmacro()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_json_update_property
#
# ..code-block::
#
#   _doxypress_json_update_property(<JSON path>)
#
# Applies update logic to a given property. The property is updated in the
# loaded JSON document, and in the stored input parameter, if one is defined
# for this property. See :ref:`algorithm<Algorithm>` for a detailed description
# of actions taken by the function.
##############################################################################
function(_doxypress_json_update_property _property)
    TPA_get(${_property}_INPUT _input_arg_name)
    TPA_get(${_property}_OVERWRITE _overwrite)
    TPA_get(${_property}_UPDATER _updater)

    set(_input_value "")
    if (_input_arg_name)
        # there is an input parameter bound to this property; need to get it
        _doxypress_get_input_value(${_input_arg_name} _input_value)
        _doxypress_action(${_property} input "${_input_value}")
    endif ()
    set(_value "${_input_value}")

    if (_value STREQUAL "")
        _JSON_get(doxypress.${_property} _value)
        _doxypress_action(${_property} source "${_value}")
    endif ()
    # now, _value is either an input argument or a JSON value (or an empty
    # string)
    if (_value STREQUAL "" OR _overwrite)
        _doxypress_setter_updater_default(${_property} _value)
    else ()
        _doxypress_updater_merge(${_property} "${_value}" "${_input_value}" _value)
    endif ()

    _JSON_set(doxypress.${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_arg_name)
        TPA_set(${_input_arg_name} "${_value}")
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_get_input_value
#
# .. code-block:: cmake
#
#   _doxypress_get_input_value(<input argument> <output variable>)
#
# Finds the input argument ``_input_arg_name`` in the current TPA scope,
# converts `CMake`'s boolean values to ``true``/``false`` format, and writes
# the result into the output variable.
#
# Parameters:
#
# * ``_input_arg_name`` an input parameter to read
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_get_input_value _input_arg_name _out_var)
    TPA_get(${_input_arg_name} _input_value)

    # convert CMake booleans to JSON's
    if ("${_input_value}" STREQUAL TRUE)
        set(_input_value true)
    endif ()
    if ("${_input_value}" STREQUAL FALSE)
        set(_input_value false)
    endif ()
    set(${_out_var} "${_input_value}" PARENT_SCOPE)
endfunction()

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

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_setter_updater_default
#
# .. code-block:: cmake
#
#   _doxypress_setter_updater_default(<JSON path> <output variable>)
#
# Helper function that handles `setter` -> `updater` -> `default` part of the
# property update logic.
#
# Parameters:
#
# * ``_property`` a property to update, specified by its JSON path
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_setter_updater_default _property _out_var)
    TPA_get(${_property}_SETTER _setter)
    # TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_DEFAULT _default)

    set(_value "")
    if (_setter)
        _doxypress_log(DEBUG "call setter ${_setter}")
        _doxypress_action(${_property} setter "${_value}")
        _doxypress_call(_doxypress_${_setter} _value)
    endif ()
    if (_updater)
        _doxypress_log(DEBUG "call updater ${_updater}")
        _doxypress_action(${_property} updater "${_value}")
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
    set(${_out_var} ${_value} PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_updater_merge
#
# .. code-block:: cmake
#
#   _doxypress_updater_merge(<JSON path>
#                            <value>
#                            <input argument>
#                            <output variable>)
#
# Helper function that handles `merge` -> `update` part of the property update
# logic.
#
# Parameters:
#
# * ``_property`` a property to update, specified by its JSON path
# * ``_value`` the property's current value, read from JSON; could be empty
# * ``_input_value`` the value of ``_property`` from a corresponding input
#   parameter
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_updater_merge _property _value _input_value _out_var)
    # if it's an array and input was non-empty, merge the two
    # _doxypress_merge_lists()
    TPA_get(doxypress.${_property} _json_value)
    if (NOT _input_value STREQUAL "" AND "${_json_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
        _JSON_get(doxypress.${_property} _json_value)
        foreach (_val ${_value})
            list(APPEND _json_value "${_val}")
        endforeach ()
        set(_value ${_json_value})
        _doxypress_action(${_property} merge "${_value}")
    endif ()

    if (_updater)
        _doxypress_call(_doxypress_${_updater} "${_value}" _value)
    endif ()
    set(${_out_var} ${_value} PARENT_SCOPE)
endfunction()