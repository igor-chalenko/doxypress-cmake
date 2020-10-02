##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
# @file JSONFunctions.cmake
# @brief Contains functions that provide read/write access to JSON documents.
# @author Igor Chalenko
##############################################################################

##############################################################################
# @defgroup JSONFunctions JSON-related functions
##############################################################################

# "New" IN_LIST syntax
cmake_policy(SET CMP0057 NEW)

##############################################################################
# @brief Converts a given value into a properly formatted JSON value:
# * booleans are converted to `true` or `false`;
# * numbers are written "as-is";
# * strings are written with quotes around them, if not quoted already, or
#   "as-is" otherwise.
#
# @param[in]  _value             input value
# @param[out] _out_var           output variable
# @return a value suited for putting into a JSON document
##############################################################################
function(JSON_format _value _out_var)
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
# @brief Given a JSON path, returns a value located at that path. The input
# variable's name is the JSON path, and its value is the value in the original
# JSON document. If the input property is a JSON leaf, the value of the input
# variable is formatted and returned. If it is a JSON array, nested properties
# of that array are collected into a list and that list is returned.
#
# @param[in]  _path              a variable created by `sbeParseJson`
# @param[out] _out_var           output variable
# @return the value under the JSON path `_path`
##############################################################################
function(JSON_get _path _out_var)
    TPA_get(${_path} _value)
    if ("${_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
        if (NOT DEFINED CMAKE_MATCH_2)
            set(__array_length 1)
        else ()
            set(__array_length "${CMAKE_MATCH_2}")
            math(EXPR __array_length "${__array_length} + 1")
        endif ()
        set(_i 0)
        set(_list_value "")
        # read the array
        while (_i LESS ${__array_length})
            #list(APPEND _list_value ${${_path}_${_i}})
            TPA_get(${_path}_${_i} _value)
            list(APPEND _list_value ${_value})
            math(EXPR _i "${_i}+1")
        endwhile ()
        set(${_out_var} "${_list_value}" PARENT_SCOPE)
    else ()
        set(${_out_var} "${_value}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
# @brief Sets a value for a leaf under a given JSON path. If the input property
# under `_path` is a JSON leaf, the value of `_path` is simply updated.
# If it is a JSON array, nested properties of that array are removed, and
# `_new_value` is treated as a list, which is then decomposed into individual
# values inside the JSON array.
#
# @param[in] _path              a variable created by `sbeParseJson`
# @param[in] _new_value         a value to put under the path `_path`
##############################################################################
function(JSON_set _path _new_value)
    TPA_get(${_path} _current_value)
    set(_new_value ${_new_value})
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _doxypress)
    if (_current_value MATCHES "^([0-9]+;)*([0-9]+)$")
        if (NOT DEFINED CMAKE_MATCH_2)
            set(__array_length 1)
        else ()
            set(__array_length "${CMAKE_MATCH_2}")
            math(EXPR __array_length "${__array_length} + 1")
        endif ()
        set(_i 0)
        while (_i LESS ${__array_length})
            list(REMOVE_ITEM _doxypress "${_path}_${_i}")
            math(EXPR _i "${_i} + 1")
        endwhile ()
        set(_index_value "")
        unset(_length)
        list(LENGTH _new_value _length)
        set(_i 0)
        list(FIND _doxypress "${_path}" _ind)
        math(EXPR _ind "${_ind}+1")
        while (_i LESS ${_length})
            list(GET _new_value ${_i} _next_value)
            # JSON_format("${_next_value}" _next_value)
            doxypress_log(DEBUG "set ${_path}_${_i} to ${_next_value}...")
            TPA_set(${_path}_${_i} ${_next_value})
            list(APPEND _index_value ${_i})
            list(INSERT _doxypress ${_ind} "${_path}_${_i}")
            math(EXPR _i "${_i}+1")
            math(EXPR _ind "${_ind}+1")
        endwhile ()
        TPA_set(${_path} "${_index_value}")
    else ()
        # JSON_format("${_new_value}" _new_value)
        doxypress_log(DEBUG "${_path} -> ${_new_value}...")
        TPA_set(${_path} "${_new_value}")
    endif ()
    TPA_set(${_DOXYPRESS_PROJECT_KEY} "${_doxypress}")
endfunction()

# -----------------------------------------------------------------------------
# @brief Forms a JSON document from a flat list of variables, previously
# created by `sbeParseJson`. Handles the format of Doxypress configuration
# files, not arbitrary JSON.
#
# @param[in] _variables        list of variables that represents flattened
#                              JSON file that was previously parsed via
#                              `sbeParseJson`
# @param[out] _out_json        serialized JSON
# -----------------------------------------------------------------------------
function(JSON_serialize _variables _out_json)
    set(_json "{\n")
    set(_section "")

    # todo ?
    set(_array_length 0)
    foreach (_var ${_variables})
        TPA_get(${_var} _value)

        # search for an override
        doxypress_cut_prefix(${_var} _var_without_prefix)
        if (NOT "${_var_without_prefix}" STREQUAL "input.input-source")
            if (DEFINED ${_var_without_prefix})
                set(_message "CMake override ${_var_without_prefix} found:")
                doxypress_log(DEBUG "${_message} ${${_var_without_prefix}}")
                set(_value "${${_var_without_prefix}}")
            endif()
        endif ()

        # parse var
        if (_var MATCHES "doxypress\\.([a-z0-9_\\-]+)\\.([a-z0-9_\\-]+)")
            set(_key1 "${CMAKE_MATCH_1}")
            set(_key2 "${CMAKE_MATCH_2}")
            if (_var MATCHES "(.*)_([0-9]+)")
                if (_array_length EQUAL 0)
                    string(APPEND _json "\t\"${_value}\"\n")
                    string(APPEND _json "\t],\n")
                else ()
                    math(EXPR _array_length "${_array_length}-1")
                    string(APPEND _json "\t\"${_value}\",\n")
                endif ()
                continue()
            endif ()
            list(FIND _variables "${_var}_0" array_ind)
            if (NOT array_ind EQUAL -1 AND "${_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
                # handle array
                set(_index2 "${CMAKE_MATCH_2}")
                if (DEFINED _index2)
                    set(_array_length ${_index2})
                    if (NOT _section STREQUAL _key1)
                        set(_section ${_key1})
                        string(LENGTH "${_json}" _length)
                        math(EXPR _length "${_length} - 2")
                        string(SUBSTRING "${_json}" 0 ${_length} _json)
                        string(APPEND _json "},\n")
                        string(APPEND _json "\"${_key1}\": {\n")
                    endif ()
                    string(APPEND _json "\t\t\"${_key2}\": [\n")
                endif ()
            else ()
                if (NOT _section)
                    set(_section ${_key1})
                    string(APPEND _json "\"${_section}\": {\n")
                    JSON_format("${_value}" _value)
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
                        JSON_format("${_value}" _value)
                        string(APPEND _json "\t\"${_key2}\": ${_value},\n")
                    else ()
                        JSON_format("${_value}" _value)
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

                JSON_format("${_value}" _value)
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
