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
# * properties derived by `CMake` are updated from the corresponding variables
#   and targets.
#
# These functions are never called directly; they are configured to participate
# in the property :ref:`transformation<Project file generator>` process.
##############################################################################

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_dia_path
#
# ..  code-block:: cmake
#
#    _doxypress_set_dia_path(_out_var)
#
# Sets the ``dot.dia-path`` configuration property. Puts the result into
# ``_out_var``.
##############################################################################
function(_doxypress_set_dia_path _out_var)
    if (TARGET Doxypress::dia)
        get_target_property(DIA_PATH Doxypress::dia IMPORTED_LOCATION)
        set(${_out_var} "${DIA_PATH}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_latex_cmd_name
#
# ..  code-block:: cmake
#
#    _doxypress_set_latex_cmd_name(_out_var)
#
# Sets the property ``output-latex.latex-cmd-name`` to the value of
# ``PDFLATEX_COMPILER``, previously configured by ``find_package(LATEX)``.
# Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_latex_cmd_name _out_var)
    if (NOT "${PDFLATEX_COMPILER}" STREQUAL PDFLATEX_COMPILER-NOTFOUND)
        set(${_out_var} "${PDFLATEX_COMPILER}" PARENT_SCOPE)
    else ()
        if (LATEX_FOUND)
            set(${_out_var} "${LATEX_COMPILER}" PARENT_SCOPE)
        else ()
            set(${_out_var} "" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_makeindex_cmd_name
#
# ..  code-block:: cmake
#
#    _doxypress_set_makeindex_cmd_name(_out_var)
#
# Sets ``output-latex.makeindex-cmd-name`` to the value of
# `MAKEINDEX_COMPILER` set by `find_package(LATEX)`. Puts the result into
# ``_out_var``.
##############################################################################
function(_doxypress_set_makeindex_cmd_name _out_var)
    if (NOT "${MAKEINDEX_COMPILER}" STREQUAL "MAKEINDEX_COMPILER-NOTFOUND")
        set(${_out_var} "${MAKEINDEX_COMPILER}" PARENT_SCOPE)
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_project_file
#
# .. code-block:: cmake
#
#   _doxypress_update_project_file(_file_name _out_var)
#
# Transforms a relative file name ``_file_name`` into an absolute one, if
# needed, and puts the result into ``_out_var``. Does nothing otherwise.
##############################################################################
function(_doxypress_update_project_file _file_name _out_var)
    set(_result "")
    if (NOT IS_ABSOLUTE ${_file_name})
        get_filename_component(_result
                "${_file_name}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_input_target
#
# .. code-block:: cmake
#
#   _doxypress_set_input_target(_out_var)
#
# Sets the output variable ``_out_var`` to ``${PROJECT_NAME}`` if a target with
# that name exists. Clears the output variable otherwise.
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
#   _doxypress_set_warn_format(_out_var)
#
# Sets the value of the configuration property ``messages.warn-format``
# depending on the current build tool. Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_warn_format _out_var)
    if ("${CMAKE_BUILD_TOOL}" MATCHES "(msdev|devenv)")
        set(${_out_var} "$file($line) : $text" PARENT_SCOPE)
    else ()
        set(${_out_var} "$file:$line: $text" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_dot_path
#
# .. code-block:: cmake
#
#   _doxypress_set_dot_path(_out_var)
#
# Sets the ``dot.dot-path`` configuration property. Uses result of the call
# ``find_package(Doxypress)``. Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_dot_path _out_var)
    if (TARGET Doxypress::dot)
        get_target_property(DOT_PATH Doxypress::dot IMPORTED_LOCATION)
        set(${_out_var} "${DOT_PATH}" PARENT_SCOPE)
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
# Walks through directory paths ``_paths`` and updates relative
# ones by prepending ``CMAKE_CURRENT_SOURCE_DIR``. Does nothing
# to absolute directory paths. Writes updated list to ``_out_var``.
##############################################################################
function(_doxypress_update_input_source _paths _out_var)
    set(_inputs "")
    # _doxypress_log(DEBUG "input sources before update: ${_sources}")
    if (_paths)
        foreach (_path ${_paths})
            if (NOT IS_ABSOLUTE "${_path}")
                get_filename_component(_path
                        "${_path}" ABSOLUTE
                        BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
            endif ()
            list(APPEND _inputs "${_path}")
        endforeach ()
    else ()
        TPA_get("INPUT_TARGET" _target)
        if (TARGET ${_target})
            get_target_property(_inputs
                    "${_target}"
                    INTERFACE_INCLUDE_DIRECTORIES)
            _doxypress_log(DEBUG "inputs from ${_input_target}: ${_inputs}")
        endif ()
    endif ()

    set(_result "")
    foreach(_input ${_inputs})
        message(STATUS "massaging ${_input}...")
        string(REGEX MATCH "\\$<BUILD_INTERFACE:(.*)?>" _input_copy1 "${_input}")
        set(_input_copy1 "${CMAKE_MATCH_1}")
        message(STATUS "_input_copy1 = ${_input_copy1}")
        string(REGEX MATCH "\\$<INSTALL_INTERFACE:(.*)?>" _input_copy2 "${_input}")
        set(_input_copy2 "${CMAKE_MATCH_1}")
        message(STATUS "_input_copy2 = ${_input_copy2}")
        if (_input_copy1)
            message(STATUS "!!! convert to ${_input_copy1}...")
            file(GLOB_RECURSE _inputs ${_input_copy1}/*)
            list(APPEND _result "${_inputs}")
        elseif(NOT _input_copy2)
            message(STATUS "!!! unchanged...")
            list(APPEND _result "${_input}")
        endif()
    endforeach()
     _doxypress_log(DEBUG "input sources after update: ${_result}")
    set(${_out_var} "${_result}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_example_source
#
# .. code-block:: cmake
#
#   _doxypress_update_example_source(_directories _out_var)
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
                        "${_dir}" ABSOLUTE
                        BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
            endif ()
            list(APPEND _result "${_dir}")
        endforeach ()
        set(${_out_var} "${_result}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_output_dir
#
# .. code-block:: cmake
#
#   _doxypress_update_output_dir(_directory _out_var)
#
# Updates a given output directory ``_directory``:
#
# * a relative directory path is converted into an absolute one by prepending
#   *CMAKE_CURRENT_BINARY_DIR*;
# * an absolute path stays unchanged. Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_update_output_dir _directory _out_var)
    if (_directory)
        if (NOT IS_ABSOLUTE "${_directory}")
            get_filename_component(_dir "${_directory}"
                    ABSOLUTE
                    BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
            set(${_out_var} "${_dir}" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_have_dot
#
# .. code-block:: cmake
#
#   _doxypress_set_have_dot(_out_var)
#
# Sets ``dot.have-dot`` configuration flag depending on `Graphviz` ``dot``
# presence. Uses the results of the ``find_package(DoxypressCMake)`` call.
# Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_have_dot _out_var)
    if (TARGET Doxypress::dot)
        set(${_out_var} true PARENT_SCOPE)
    else ()
        set(${_out_var} false PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_example_source
#
# .. code-block:: cmake
#
#   _doxypress_set_example_source(_out_var)
#
# Setter for the property ``input.example-source``. Searches for
# the sub-directories  [``example``, ``examples``] in the current source
# directory, and collects found ones. Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_example_source _out_var)
    _doxypress_find_directory(
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "example;examples"
            _example_path
    )
    set(${_out_var} "${_example_path}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_set_target_name
#
# .. code-block:: cmake
#
#   _doxypress_set_target_name(_out_var)
#
# Sets the ``TARGET_NAME`` parameter when it was not given explicitly:
#
# * if ``INPUT_TARGET`` is not empty, sets it to ``${INPUT_TARGET}.doxypress``;
# * otherwise, sets it to ``${PROJECT_NAME}``
#
# Puts the result into ``_out_var``.
##############################################################################
function(_doxypress_set_target_name _out_var)
    TPA_get(INPUT_TARGET _input_target)
    if (_input_target STREQUAL "")
        set(${_out_var} "${PROJECT_NAME}.doxypress" PARENT_SCOPE)
    else()
        set(${_out_var} "${_input_target}.doxypress" PARENT_SCOPE)
    endif()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_update_generate_latex
#
# .. code-block:: cmake
#
#   _doxypress_update_generate_latex(_generate_latex _out_var)
#
# If ``.tex`` generation was requested (``_generate_latex`` is ``true``), but
# no LATEX was found in the local environment, ``_out_var`` is set to ``false``.
# Otherwise, it's set to ``true``.
##############################################################################
macro(_doxypress_update_generate_latex _generate_latex _out_var)
    if (${_generate_latex})
        if (NOT DEFINED LATEX_FOUND)
            _doxypress_log(INFO "LaTex files requested, importing LATEX...")
            find_package(LATEX OPTIONAL_COMPONENTS MAKEINDEX PDFLATEX)
            TPA_set(LATEX_FOUND ${LATEX_FOUND})
        endif()
        if (NOT LATEX_FOUND)
            _doxypress_log(WARN "LATEX was not found; skip LaTex generation.")
            set(_generate_latex false)
        endif()
    endif()
    set(${_out_var} ${_generate_latex})
endmacro()
