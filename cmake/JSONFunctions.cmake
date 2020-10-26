##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
#
# JSON manipulation functions
# ---------------------------
#
# These functions implement read/write access to `DoxyPress` project files.
# JSON structure is treated as a list of properties, where property is
# identified by its JSON path. Here's a few examples:
#
# .. code-block:: cpp
#
#    input.input-source
#    messages.warnings
#    dot.have-dot
#
# When a project file is loaded, a prefix ``doxypress.`` is added to every
# property's path by the JSON parser implementation. This has to be taken into
# account when the loaded properties are accessed:
#
# .. code-block:: cmake
#
#    JSON_get(doxypress.input.input-source _inputs)
#    JSON_get(doxypress.messages.warnings _warnings)
#    JSON_get(doxypress.dot.have-dot _have_dot)
#
# There are specialized accessor functions that encapsulate prefix addition:
#
# .. code-block:: cmake
#
#    _doxypress_get(input.input-source _inputs)
#    _doxypress_get(messages.warnings _warnings)
#    _doxypress_get(dot.have-dot _have_dot)
#
# Parsed JSON document is stored in the current :ref:`TPA scope` under the key
# ``_DOXYPRESS_PROJECT_KEY``.
##############################################################################

##############################################################################
#.rst:
# .. cmake:command:: _JSON_get
#
# .. code-block:: cmake
#
#    _JSON_get(_path _out_var)
#
# Given a JSON path ``_path``, returns a value located at that path in
# the currently loaded project file:
#
# * If the input property is a JSON leaf, the value of ``_path``  is simply
#   written into ``_out_var``;
# * If it is a JSON array, nested properties of that array are collected into
#   a list, and that list is written into ``_out_var``. Only one nested level
#   is collected; if a property in the array is itself an array, the result is
#   undefined.
##############################################################################
function(_JSON_get _path _out_var)
    _doxypress_assert_not_empty("${_path}")
    _JSON_array_length(${_path} _array_length)
    if (${_array_length} GREATER -1)
        set(_i 0)
        set(_list_value "")
        # read the array
        while (_i LESS ${_array_length})
            TPA_get(${_path}_${_i} _value)
            list(APPEND _list_value ${_value})
            math(EXPR _i "${_i}+1")
        endwhile ()
        set(${_out_var} "${_list_value}" PARENT_SCOPE)
    else ()
        TPA_get(${_path} _value)
        set(${_out_var} "${_value}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _JSON_set
#
# .. code-block:: cmake
#
#    _JSON_set(_path _new_value)
#
# Updates a :ref:`property<property-reference-label>` identified by the JSON
# path ``_path``. JSON source is taken from the current :ref:`TPA scope`.
#
# * If the path ``_path`` is a JSON leaf, the value of ``_path`` is simply
#   set to ``_new_value``;
# * If it is a JSON array, nested properties of that array are removed,
#   ``_new_value`` is treated as a list that is then decomposed into
#   individual array values inside ``_path``.
##############################################################################
function(_JSON_set _path _new_value)
    _doxypress_assert_not_empty("${_path}")
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _doxypress)
    _JSON_array_length(${_path} _array_length)
    if (_array_length GREATER -1)
        set(_i 0)
        while (_i LESS ${_array_length})
            list(REMOVE_ITEM _doxypress "${_path}_${_i}")
            math(EXPR _i "${_i} + 1")
        endwhile ()
        set(_index_value "")
        unset(_length)
        list(LENGTH _new_value _length)
        set(_i 0)
        list(FIND _doxypress "${_path}" _ind)
        math(EXPR _ind "${_ind}+1")
        if (${_length} EQUAL 0)
            set(_length 1)
            set(_new_value ";")
        endif()
        while (_i LESS ${_length})
            list(GET _new_value ${_i} _next_value)
            _doxypress_log(DEBUG "set ${_path}_${_i} to ${_next_value}...")
            TPA_set(${_path}_${_i} "${_next_value}")
            list(APPEND _index_value ${_i})
            list(INSERT _doxypress ${_ind} "${_path}_${_i}")
            math(EXPR _i "${_i}+1")
            math(EXPR _ind "${_ind}+1")
        endwhile ()
        TPA_set(${_path} "${_index_value}")
    else ()
        _doxypress_log(DEBUG "${_path} -> ${_new_value}...")
        TPA_set(${_path} "${_new_value}")
    endif ()
    TPA_set(${_DOXYPRESS_PROJECT_KEY} "${_doxypress}")
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _JSON_serialize
#
# .. code-block:: cmake
#
#    _JSON_serialize(_variables _out_json)
#
# Forms a JSON document from a flat list of variables in ``_variables``,
# previously created by ``sbeParseJson``. Handles format of `DoxyPress`
# project files, not arbitrary JSON. The resulting JSON is written into
# the variable, designated by ``_out_json`` in the parent scope.
##############################################################################
function(_JSON_serialize _variables _out_json)
    set(_json "{\n")
    set(_section "")

    set(_array_length 0)
    foreach (_var ${_variables})
        TPA_get(${_var} _value)

        # parse var
        if (_var MATCHES "doxypress\\.([a-z0-9_\\-]+)\\.([a-z0-9_\\-]+)")
            set(_key1 "${CMAKE_MATCH_1}")
            set(_key2 "${CMAKE_MATCH_2}")
            if (_var MATCHES "(.*)_([0-9]+)")
                if (_array_length EQUAL 1)
                    string(APPEND _json "\t\"${_value}\"\n")
                    string(APPEND _json "\t],\n")
                else ()
                    math(EXPR _array_length "${_array_length}-1")
                    string(APPEND _json "\t\"${_value}\",\n")
                endif ()
                continue()
            endif ()
            _JSON_array_length(${_var} _array_length)
            if (${_array_length} GREATER -1)
                # handle array
                if (NOT _section STREQUAL _key1)
                    set(_section ${_key1})
                    string(LENGTH "${_json}" _length)
                    math(EXPR _length "${_length} - 2")
                    string(SUBSTRING "${_json}" 0 ${_length} _json)
                    string(APPEND _json "},\n")
                    string(APPEND _json "\"${_key1}\": {\n")
                endif ()
                string(APPEND _json "\t\t\"${_key2}\": [\n")
            else ()
                if (NOT _section)
                    set(_section ${_key1})
                    string(APPEND _json "\"${_section}\": {\n")
                    _JSON_format("${_value}" _value)
                    string(APPEND _json "\t\"${_key2}\": ${_value},\n")
                else ()
                    string(COMPARE EQUAL "${_section}" "" _result)
                    if (NOT _section STREQUAL _key1)
                        set(_section ${_key1})
                        if (NOT _result)
                            string(LENGTH "${_json}" _length)
                            math(EXPR _length "${_length} - 2")
                            string(SUBSTRING "${_json}" 0 ${_length} _json)
                            string(APPEND _json "},\n")
                        endif ()
                        string(APPEND _json "\"${_key1}\": {\n")
                        _JSON_format("${_value}" _value)
                        string(APPEND _json "\t\"${_key2}\": ${_value},\n")
                    else ()
                        _JSON_format("${_value}" _value)
                        string(APPEND _json "\t\"${_key2}\": ${_value},\n")
                    endif ()
                endif ()
            endif ()
        else ()
            if (_var MATCHES "doxypress\\.([a-z0-9_\\-]+)")
                set(_key1 "${CMAKE_MATCH_1}")
                string(COMPARE EQUAL "${_section}" "" result)
                if (NOT result)
                    set(_section "")
                    string(LENGTH "${_json}" _length)
                    math(EXPR _length "${_length} - 2")
                    string(SUBSTRING "${_json}" 0 ${_length} _json)
                    string(APPEND _json "\n},\n")
                endif ()

                _JSON_format("${_value}" _value)
                string(APPEND _json "\t\"${_key1}\": ${_value},\n")
            endif ()
        endif ()
    endforeach ()
    string(LENGTH "${_json}" _length)
    math(EXPR _length "${_length} - 2")
    string(SUBSTRING "${_json}" 0 ${_length} _json)
    string(APPEND _json "\t}")
    string(APPEND _json "}")

    set(${_out_json} "${_json}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _JSON_format
#
# .. code-block:: cmake
#
#    _JSON_format(_value _out_var)
#
# Converts a given variable ``_value`` into a properly formatted JSON value:
#
# * booleans are converted to `true` or `false`;
# * numbers are written "as-is";
# * strings are written with quotes around them, if not quoted already, or
#   "as-is" otherwise.
#
# The converted value is written into the output variable ``_out_var``.
##############################################################################
function(_JSON_format _value _out_var)
    set(_true_values true TRUE ON on)
    set(_false_values false FALSE OFF off)
    if ("${_value}" IN_LIST _true_values)
        set(${_out_var} "true" PARENT_SCOPE)
    else ()
        if ("${_value}" IN_LIST _false_values)
            set(${_out_var} "false" PARENT_SCOPE)
        else ()
            if (_value MATCHES "^[0-9]+$")
                set(${_out_var} "${_value}" PARENT_SCOPE)
            else ()
                if (_value MATCHES "^\"(.*)\"$")
                    set(${_out_var} "${_value}" PARENT_SCOPE)
                else()
                    set(${_out_var} "\"${_value}\"" PARENT_SCOPE)
                endif()
            endif ()
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _JSON_array_length
#
# .. code-block:: cmake
#
#    _JSON_array_length(_path _out_var)
#
# There are two possibilities:
#
#  * If the JSON path ``_path`` in the currently loaded JSON contains a
#    node, puts the number of leaves under that node into ``_out_var``.
#  * If it contains a leaf, puts ``-1`` into ``_out_var``.
##############################################################################
function(_JSON_array_length _path _out_var)
    _doxypress_assert_not_empty("${_path}")

    TPA_get(${_path} _current_value)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _doxypress)
    if ("${_current_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
        if ("${_path}_0" IN_LIST _doxypress)
            if (NOT DEFINED CMAKE_MATCH_2)
                set(${_out_var} 1 PARENT_SCOPE)
            else()
                math(EXPR _length "${CMAKE_MATCH_2} + 1")
                set(${_out_var} ${_length} PARENT_SCOPE)
            endif()
            return()
        endif()
    endif()
    set(${_out_var} -1 PARENT_SCOPE)
endfunction()
