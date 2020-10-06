##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# Setters and updaters
# --------------------
#
# These functions implement property update logic:
#
# * relative directory names are converted into absolute ones;
# * properties that depend on CMake are updated from the corresponding variables
#   and targets.
#
# These functions are never called directly; they are configured to participate
# in the JSON update pipeline via ``_doxypress_json_property``.
##############################################################################

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_dia_path
#
# Sets the ``dot.dia-path`` configuration property. Uses results of the
# ``find_package(Doxypress)`` call.
##############################################################################
function(_doxypress_set_dia_path _out_var)
    if (TARGET Doxypress::dia)
        get_target_property(DIA_PATH Doxypress::dia IMPORTED_LOCATION)
        set(${_out_var} "${DIA_PATH}" PARENT_SCOPE)
        _doxypress_action("dot.dia-path" setter "${DIA_PATH}")
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_latex_cmd_name
#
# Sets the property ``output-latex.latex-cmd-name`` to the value of
# ``PDFLATEX_COMPILER``, previously configured by ``find_package(LATEX)``.
##############################################################################
function(_doxypress_set_latex_cmd_name _out_var)
    if (NOT "${PDFLATEX_COMPILER}" STREQUAL PDFLATEX_COMPILER-NOTFOUND)
        set(${_out_var} "${PDFLATEX_COMPILER}" PARENT_SCOPE)
        _doxypress_action(${_DOXYPRESS_LATEX_CMD_NAME}
                setter "${PDFLATEX_COMPILER}")
    else ()
        if (LATEX_FOUND)
            set(${_out_var} "${LATEX_COMPILER}" PARENT_SCOPE)
            _doxypress_action(${_DOXYPRESS_LATEX_CMD_NAME}
                    setter "${LATEX_COMPILER}")
        else ()
            set(${_out_var} "" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_makeindex_cmd_name
#
# .. code-block:: cmake
#
#   _doxypress_set_makeindex_cmd_name(<output variable>)
#
## @brief Sets ``output-latex.makeindex-cmd-name`` to the value of
## `MAKEINDEX_COMPILER` set by `find_package(LATEX)`.
##############################################################################
function(_doxypress_set_makeindex_cmd_name _out_var)
    if (NOT "${MAKEINDEX_COMPILER}" STREQUAL "MAKEINDEX_COMPILER-NOTFOUND")
        set(${_out_var} "${MAKEINDEX_COMPILER}" PARENT_SCOPE)
        _doxypress_action(${_DOXYPRESS_MAKEINDEX_CMD_NAME}
                setter "${MAKEINDEX_COMPILER}")
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_project_file
#
# Sets `output-latex.latex-cmd-name` to the value of `PDFLATEX_COMPILER`,
# which was previously set by `find_package(LATEX)`.
##############################################################################
function(_doxypress_update_project_file _project_file _out_var)
    set(_result "")
    if (NOT IS_ABSOLUTE ${_project_file})
        get_filename_component(_result
                ${CMAKE_CURRENT_SOURCE_DIR}/${_project_file} ABSOLUTE)
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_dia_path
#
# .. code-block:: cmake
#
#   _doxypress_set_input_target(<output variable>)
#
# Sets the output variable to ``PROJECT_NAME`` if a target with that name
# exists. Clears the output variable otherwise.
##############################################################################
function(_doxypress_set_input_target _out_var)
    if (TARGET ${PROJECT_NAME})
        set(${_out_var} ${PROJECT_NAME} PARENT_SCOPE)
    else ()
        set(${_out_var} "" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_warn_format
#
# .. code-block:: cmake
#
#   _doxypress_set_warn_format(<output variable>)
#
# Sets the value of the configuration property ``messages.warn-format``
# depending on the current build tool.
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
#.rst:
# .. cmake:command:: _doxypress_set_dot_path
#
# .. code-block:: cmake
#
#   _doxypress_set_dot_path(<output variable>)
#
# Sets the ``dot.dot-path`` configuration property. Uses result of the call
# ``find_package(Doxypress)``.
##############################################################################
function(_doxypress_set_dot_path _out_var)
    if (TARGET Doxypress::dot)
        get_target_property(DOT_PATH Doxypress::dot IMPORTED_LOCATION)
        set(${_out_var} "${DOT_PATH}" PARENT_SCOPE)
        _doxypress_action("dot.dot-path" setter "${DOT_PATH}")
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_input_source
#
# .. code-block:: cmake
#
#   _doxypress_update_input_source(<directories> <output variable>)
#
# Walks through directory paths ``_sources`` and updates relative
# ones by prepending ``CMAKE_CURRENT_SOURCE_DIR``. Does nothing
# to absolute directory paths. Writes updated list to ``_out_var``.
##############################################################################
function(_doxypress_update_input_source _directories _out_var)
    set(_inputs "")
    # _doxypress_log(DEBUG "input sources before update: ${_sources}")
    if (_directories)
        foreach (_path ${_directories})
            if (NOT IS_ABSOLUTE ${_path})
                get_filename_component(_path ${CMAKE_CURRENT_SOURCE_DIR}/${_path}
                        ABSOLUTE)
            endif ()
            list(APPEND _inputs ${_path})
        endforeach ()
    else ()
        TPA_get("INPUT_TARGET" _input_target)
        if (TARGET ${_input_target})
            get_target_property(_inputs "${_input_target}"
                    INTERFACE_INCLUDE_DIRECTORIES)
            _doxypress_log(DEBUG
                    "input sources from ${_input_target}: ${_inputs}")
        endif ()
    endif ()
    # _doxypress_log(DEBUG "input sources after update: ${_inputs}")
    _doxypress_action(${_DOXYPRESS_INPUT_SOURCE} "updater" "${_inputs}")
    set(${_out_var} "${_inputs}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_example_source
#
# .. code-block:: cmake
#
#   _doxypress_update_example_source(<directories> <output variable>)
#
# Walks through directory paths ``_directories`` and updates relative
# ones by prepending ``CMAKE_CURRENT_SOURCE_DIR``. Does nothing
# to absolute directory paths. Writes updated list to ``_out_var``.
##############################################################################
function(_doxypress_update_example_source _directories _out_var)
    if (_directories)
        set(_result "")
        foreach (_dir ${_directories})
            if (NOT IS_ABSOLUTE "${_dir}")
                get_filename_component(_dir
                        "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}"
                        ABSOLUTE)
            endif ()
            list(APPEND _result "${_dir}")
        endforeach ()
        _doxypress_action(${_DOXYPRESS_EXAMPLE_SOURCE} "updater" "${_result}")
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_output_dir
#
# .. code-block:: cmake
#
#   _doxypress_update_output_dir(<directory> <output variable>)
#
# Updates a given output directory:
#
# * a relative directory path is converted into an absolute one by prepending
#   ``CMAKE_CURRENT_BINARY_DIR``;
# * an absolute path stays unchanged.
##############################################################################
function(_doxypress_update_output_dir _directory _out_var)
    if (_directory)
        if (NOT IS_ABSOLUTE "${_directory}")
            get_filename_component(_dir
                    "${CMAKE_CURRENT_BINARY_DIR}/${_directory}"
                    ABSOLUTE)
            set(${_out_var} "${_dir}" PARENT_SCOPE)
            _doxypress_action("general.output-dir" "updater" "${_dir}")
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_have_dot
#
# .. code-block:: cmake
#
#   _doxypress_set_have_dot(<output variable>)
#
# Sets ``dot.have-dot`` configuration flag depending on `Graphviz` ``dot``
# presence. Uses the results of the ``find_package(DoxypressCMake)`` call.
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

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_input_target
#
# .. code-block:: cmake
#
#   _doxypress_set_input_target(<output variable>)
#
# Tries to default the input target name. If a target ``PROJECT_NAME`` exists,
# the output variable is set to ``PROJECT_NAME``. The output variable is cleared
# otherwise.
##############################################################################
function(_doxypress_set_input_target _out_var)
    if (TARGET ${PROJECT_NAME})
        set(${_out_var} ${PROJECT_NAME} PARENT_SCOPE)
    else ()
        set(${_out_var} "" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_example_source
#
# .. code-block:: cmake
#
#   _doxypress_set_example_source(<output variable>)
#
# Sets the `input.example-source` configuration parameter by searching one of
# ``example``, ``examples`` sub-directories in the current source directory.
##############################################################################
function(_doxypress_set_example_source _out_var)
    _doxypress_find_directory(
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "example;examples"
            _example_path
    )
    set(${_out_var} "${_example_path}" PARENT_SCOPE)
    _doxypress_action(${_DOXYPRESS_EXAMPLE_SOURCE} "setter" "${_example_path}")
endfunction()
