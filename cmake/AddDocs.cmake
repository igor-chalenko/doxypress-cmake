##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# AddDocs
# -------
#
# This module contains this package's public API. It's included by
# ``FindDoxypressCMake.cmake``.
##############################################################################

include(${_doxypress_dir}/Logging.cmake)
include(${_doxypress_dir}/TPA.cmake)
include(${_doxypress_dir}/JSONFunctions.cmake)
include(${_doxypress_dir}/CMakeTargetGenerator.cmake)
include(${_doxypress_dir}/ProjectFileGenerator.cmake)
include(${_doxypress_dir}/ProjectFunctions.cmake)
include(${_doxypress_dir}/PropertyHandlers.cmake)

##############################################################################
# TPA usage protocol
##############################################################################

# a list of parsed project file's properties
set(_DOXYPRESS_PROJECT_KEY "doxypress.json")
# updatable property names
set(_DOXYPRESS_JSON_PATHS_KEY "doxypress.updatable.properties")
# `doxypress_add_docs` input arguments
set(_DOXYPRESS_INPUTS_KEY "cmake.inputs")

# used throughout the code
set(_DOXYPRESS_INPUT_SOURCE "input.input-source")

##############################################################################
#.rst:
# ---------
# Functions
# ---------
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
#                       [OUTPUT_DIRECTORY] <directory>
#                       [TARGET_NAME] <name>)
#
# Generates documentation using `DoxyPress`. Performs the following tasks:
#
# * Generates a configured project file from a template file;
# * Generates targets as described
#   :ref:`here<cmake-target-generator-reference-label>`;
# * Adds the generated files to the ``install`` target, if
#   :cmake:variable:`DOXYPRESS_INSTALL_DOCS` is enabled.
#
# ================
# Input parameters
# ================
# **PROJECT_FILE**
#    JSON project file that `DoxyPress` uses as input. Antwerp will read
#    this file during CMake configuration phase, update it accordingly, write
#    the updated file back, and use the result as actual configuration. See
#    :ref:`Algorithm description` for a detailed description of what the package
#    does.
#
#    Defaults to ``DoxypressAddDocs.json``, provided with the package.
#
# .. _inputs-reference-label:
#
# **INPUTS**
#    A list of files and directories to be processed by `DoxyPress`; takes
#    priority over `INPUT_TARGET`.
#
# **INPUT_TARGET**
#    If defined (correctly), this target's property
#    `INTERFACE_INCLUDE_DIRECTORIES` determines the input sources in
#    the generated project file. If :ref:`INPUTS<inputs-reference-label>` are
#    not empty, this parameter is ignored.
#
# **INSTALL_COMPONENT**
#    Specified, an installation command for generated docs will be added to
#    the `install` target; the input parameter is used as the component name for
#    the generated files. Default is ``docs``.
#
# **OUTPUT_DIRECTORY**
#     The base directory for all the generated documentation files.
#     Default is ``doxypress-generated``.
#
# **TARGET_NAME**
#     The name of the `DoxyPress` target. Default is
#     ``${INPUT_TARGET}.doxypress`` if ``INPUT_TARGET`` is supplied, or
#     ``${PROJECT_NAME}.doxypress`` otherwise.
#
# ==================
# Property overrides
# ==================
#
# In addition to the properties handled by :cmake:command:`doxypress_add_docs`,
# it's possible to change other properties as well by using appropriate
# ``set(property value)`` commands. This could be useful if you use the default
# project file and need to change pre-defined settings, or you need to update
# a certain property based on some custom logic. In order to do so, set
# a `CMake` variable with a name that corresponds to the JSON path of a property
# you need to updated. For example, the following command will instruct
# `DoxyPress` to inline source code into the generated documentation:
#
# .. code-block:: cmake
#
#   set(source.inline-source true)
#
# .. note::
#   :cmake:command:`TPA_clear_scope` will not clear the overrides. They are
#   usual CMake variables; TPA scope doesn't store them directly. They may
#   appear in the list under the key ``_DOXYPRESS_JSON_PATHS_KEY``, but that
#   doesn't affect the overrides.
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
#   The default template generated by `DoxyPress` sets these to ``false``,
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
#   as stated in `DoxyPress` documentation (and originally in `Doxygen`'s).
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
# =========
# Algorithm
# =========
#
# * 1. The input JSON configuration is parsed into a flat list of variables as
#   described in the documentation of `sbeParseJson` from json-cmake_;
# * 2. Some of these variables get a new value. The set of JSON properties
#   to update is defined by :cmake:command:`_doxypress_params_init_properties`.
#   Each property is assigned a set of handlers, described in the documentation
#   for :cmake:command:`_doxypress_property_add`. Then, the following logic
#   is applied for each individual property:
#
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
# There are four sources of property values that may contribute to the final,
# processed project file:
#
# * input arguments provided to :ref:`doxypress_add_docs<Functions>`;
# * defaults set by `doxypress-cmake`;
# * input project file;
# * CMake variables that override the values in the project file.
#
# The order of evaluation is:
#
# ``inputs`` -> ``overrides`` -> ``project file`` -> ``defaults``
#
# That is, once a value is set upstream, downstream sources are ignored (with
# an exception for merging):
#
# * If an input value is given for a property, the override of the corresponding
#   property is ignored. The corresponding value in the input project file is
#   ignored as well unless it is an array; in this case, the input value is
#   appended to the array in the project file.
# * If an input parameter is empty, but there is an override for it,
#   the corresponding value in the input project file is ignored.
# * If an input parameter is empty and there's no override for the corresponding
#   property, the value in the project remains unchanged.
# * If the first three source didn't provide a non-empty value, the property
#   receives a default value.
#
# .. _json-cmake: https://github.com/sbellus/json-cmake
##############################################################################
function(doxypress_add_docs)
    # initialize parameter/property descriptions
    _doxypress_params_init()
    # parse input arguments
    _doxypress_inputs_parse(${ARGN})
    # get the project file name
    TPA_get(PROJECT_FILE _project_file)
    # update project file
    _doxypress_project_update("${_project_file}" _updated_project_file)
    # create target(s)
    _doxypress_add_targets("${_project_file}" "${_updated_project_file}")
    if (DOXYPRESS_INSTALL_DOCS)
        # install generated files
        _doxypress_install_docs()
    endif ()

    # clear up the TPA scope created by this function
    TPA_clear_scope()
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
# .. cmake:command:: doxypress_override_add
#
# .. code-block::
#
#   doxypress_override_add(<JSON path> <value>)
#
# Creates an :ref:`override<overrides-reference-label>` with the given value.
##############################################################################
function(doxypress_override_add _property _value)
    _doxypress_property_add(${_property} DEFAULT "${_value}" OVERWRITE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_inputs
#
# Initializes input parameters that should be parsed by
# :cmake:command:`doxypress_add_docs`.
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
# Initializes the default set of :ref:`overrides<Property overrides>`.
##############################################################################
function(_doxypress_params_init_overrides)
    doxypress_override_add("project.project-brief" "${PROJECT_DESCRIPTION}")
    doxypress_override_add("project.project-name" "${PROJECT_NAME}")
    doxypress_override_add("project.project-version" "${PROJECT_VERSION}")
    doxypress_override_add("output-latex.latex-batch-mode" true)
    doxypress_override_add("output-latex.latex-hyper-pdf" true)
    doxypress_override_add("output-latex.latex-output" "latex")
    doxypress_override_add("output-latex.latex-pdf" true)
    doxypress_override_add("output-html.html-output" "html")
    doxypress_override_add("output-html.html-file-extension" ".html")
    doxypress_override_add("output-xml.xml-output" "xml")
    doxypress_override_add("input.input-recursive" true)
    doxypress_override_add("input.example-recursive" true)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_params_init_inputs
#
# Initializes properties that are processed by the chain of handlers:
#
# .. code-block::
#
#   `input` -> `json` -> `setter` -> `updater` -> `default`
#
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
# -------
# Options
# -------
#
# .. cmake:variable:: DOXYPRESS_INSTALL_DOCS
#
# Specifies whether the files generated by `Doxypress` should be installed by
#
# .. code-block:: bash
#
#    make install INSTALL_COMPONENT
#
##############################################################################
option(DOXYPRESS_INSTALL_DOCS "Install generated documentation" OFF)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_ADD_OPEN_TARGETS
#
# Specifies whether open targets should be created for the files generated
# by `Doxypress`.
#
##############################################################################
option(DOXYPRESS_ADD_OPEN_TARGETS
        "Add open targets for the generated documentation" ON)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_PROMOTE_WARNINGS
#
# Specifies what message level ``_doxypress_log(WARN text)`` should use.
#
# .. code-block:: cmake
#
#    # DOXYPRESS_PROMOTE_WARNINGS = ON
#    _doxypress_log(WARN text) # equivalent to message(WARNING text)
#    # DOXYPRESS_PROMOTE_WARNINGS = OFF
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#
##############################################################################
option(DOXYPRESS_PROMOTE_WARNINGS "Promote log warnings to CMake warnings" OFF)

##############################################################################
#.rst:
# ---------
# Variables
# ---------
#
# .. cmake:variable:: DOXYPRESS_LAUNCHER_COMMAND
#
# Platform-specific executable for file opening:
#
# * ``start`` on Windows
# * ``open`` on OS/X
# * ``xdg-open`` on Linux
##############################################################################
if (WIN32)
    set(DOXYPRESS_LAUNCHER_COMMAND start)
elseif (NOT APPLE)
    set(DOXYPRESS_LAUNCHER_COMMAND xdg-open)
else ()
    # I didn't test this
    set(DOXYPRESS_LAUNCHER_COMMAND open)
endif ()

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_LOG_LEVEL
#
# Controls output produced by `_doxypress_log`. Set to ``INFO`` by default.
#
# .. code-block:: cmake
#
#    # DOXYPRESS_LOG_LEVEL = DEBUG
#    _doxypress_log(DEBUG text) # equivalent to message(STATUS text)
#    _doxypress_log(INFO text) # equivalent to message(STATUS text)
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYPRESS_LOG_LEVEL = INFO
#    _doxypress_log(DEBUG text) # does nothing
#    _doxypress_log(INFO text) # equivalent to message(STATUS text)
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYPRESS_LOG_LEVEL = WARN
#    _doxypress_log(DEBUG text) # does nothing
#    _doxypress_log(INFO text) # does nothing
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
##############################################################################
set(DOXYPRESS_LOG_LEVEL INFO)
