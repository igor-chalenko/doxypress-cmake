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
# .. cmake:command:: _doxypress_project_update
#
# .. code-block::
#
#   _doxypress_project_update(<project file name> <output variable>)
#
# Loads a given project file, applies update logic that was previously defined
# by :cmake:command:`_doxypress_params_init`, and saves the updated file.
# The name of the updated file is written into the output variable.
##############################################################################
macro(_doxypress_project_update input_project_file_name _out_var)
    _doxypress_project_load(${input_project_file_name})

    TPA_get("${_DOXYPRESS_JSON_PATHS_KEY}" _updatable_paths)

    foreach (_path ${_updatable_paths})
        _doxypress_update_path(${_path})
    endforeach()

    # create name for the processed project file
    _doxypress_output_project_file_name(
            ${input_project_file_name}
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
#    _doxypress_project_load(<project file name>
#
# Loads a given project file into the current TPA scope. Name of every resulting
# property is prefixed with ``doxypress.`` in order to avoid name clashes.
#
# Parameters:
#
# * ``_project_file_name`` a project file to load
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
#    _doxypress_get(<JSON path> <output variable>)
#
# Wrapper for :cmake:command:`_JSON_get` with added prefix ``doxypress.``.
#
# Parameters:
#
# * ``_property`` JSON path to read in the currently loaded JSON document
# * ``_out_var`` value of ``_property` in the loaded JSON document
##############################################################################
function(_doxypress_get _property _out_var)
    _JSON_get("doxypress.${_property}" _json_value)
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_set
#
# .. code-block:: cmake
#
#    _doxypress_set(<JSON path> <value>)
#
# Wrapper for :cmake:command:`_JSON_set` with added prefix ``doxypress.``.
#
# Parameters:
#
# * ``_property`` JSON path to update in the currently loaded JSON document
# * ``_value`` new value of ``_property`
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
#    _doxypress_call(<function name> <argument #1>)
#
# Calls a function or a macro given its name. Writes actual call code
# into a temporary file, which is then included.
#
# Parameters:
#
# * ``_id``         name of the function or macro to call
# * ``_arg1``       the first argument to the function ``_id``
# * ``ARGN``        additional arguments to pass to ``_id``
##############################################################################
macro(_doxypress_call _id _arg1)
    if (NOT COMMAND ${_id})
        message(FATAL_ERROR "Unsupported function/macro \"${_id}\"")
    else ()
        set(_helper "${CMAKE_BINARY_DIR}/helpers/macro_helper_${_id}.cmake")
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
# .. cmake:command:: _doxypress_output_project_file_name
#
# ..  code-block:: cmake
#
#   _doxypress_output_project_file_name(<input project file name>
#                                                <output variable>)
#
# Returns an absolute name of the output project file. Changes the input
# file's path while leaving the file name unchanged.
#
# Parameters:
#
# - ``_project_file_name`` input project file name
# - ``_out_var`` output project file name
##############################################################################
function(_doxypress_output_project_file_name _project_file_name _out_var)
    _doxypress_assert_not_empty("${_project_file_name}")
    get_filename_component(_name "${_project_file_name}" NAME)
    set(${_out_var} ${CMAKE_CURRENT_BINARY_DIR}/${_name} PARENT_SCOPE)
endfunction()
