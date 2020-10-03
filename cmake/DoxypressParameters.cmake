##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

function(doxypress_param_option name)
    set(_options "")
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("option_args" _option_args)
    list(APPEND _option_args ${name})
    TPA_set("option_args" "${_option_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

function(doxypress_param_string name)
    set(_options OVERWRITE)
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("one_value_args" _one_value_args)
    list(APPEND _one_value_args ${name})
    TPA_set("one_value_args" "${_one_value_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

function(doxypress_param_list name)
    set(_options "")
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("multi_value_args" _multi_value_args)
    list(APPEND _multi_value_args ${name})
    TPA_set("multi_value_args" "${_multi_value_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

##############################################################################
# @brief Attaches read/write logic to a given JSON path. Declarations made
# using this function are interpreted later by `doxypress_parse()`.
# The following arguments are recognized:
# * `INPUT_OPTION`, `INPUT_STRING`, `INPUT_LIST`
#   This JSON path can be updated if an input argument specified by one of
#   these options is provided. For example, `INPUT_OPTION GENERATE_XML`
#   specifies that `GENERATE_XML` is a valid argument of `doxypress_add_docs`.
#   If given, it will overwrite an existing value at the corresponding JSON
#   path; otherwise other handlers are invoked.
# * `DEFAULT`
#   If the value in input JSON is empty, and no other handlers set it either,
#   this value is put into JSON path.
# * `SETTER`
#   A function with this name is called if the current property value is empty.
#   The output variable becomes the new value in JSON.
# * `UPDATER`
#   A function with this name is called if the current value of the property
#   is not empty. the current value is given as an argument. The output variable
#   becomes the new value in JSON.
# * `OVERWRITE`
#   If given, the value in JSON is ignored and a given setter is called if
#   it was specified by `SETTER` argument. In other words, makes a call to
#   setter unconditional.
#
# The above handlers are invoked in the following order for each JSON property:
# * Setter f
# Resulting variables are stored using `TPA`.
##############################################################################
function(doxypress_json_property _property)
    set(_options OVERWRITE)
    set(_one_value_args
            INPUT_OPTION
            INPUT_STRING
            DEFAULT
            SETTER
            UPDATER)
    set(_multi_value_args INPUT_LIST)
    unset(IN_INPUT_STRING)
    unset(IN_INPUT_OPTION)
    unset(IN_INPUT_LIST)
    unset(IN_DEFAULT)
    unset(IN_SETTER)
    unset(IN_UPDATER)
    unset(IN_OVERWRITE)

    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    if (DEFINED IN_INPUT_STRING)
        TPA_append(one_value_args ${IN_INPUT_STRING})
        TPA_set(${_property}_INPUT ${IN_INPUT_STRING})
    endif ()
    if (DEFINED IN_INPUT_OPTION)
        TPA_append(option_args ${IN_INPUT_OPTION})
        TPA_set(${_property}_INPUT ${IN_INPUT_OPTION})
    endif ()
    if (DEFINED IN_INPUT_LIST)
        TPA_append(multi_value_args ${IN_INPUT_LIST})
        TPA_set(${_property}_INPUT "${IN_INPUT_LIST}")
    endif ()

    TPA_append(${_DOXYPRESS_JSON_PATHS_KEY} ${_property})

    if (DEFINED IN_DEFAULT)
        TPA_set(${_property}_DEFAULT ${IN_DEFAULT})
    endif ()
    if (DEFINED IN_SETTER)
        TPA_set(${_property}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${_property}_UPDATER ${IN_UPDATER})
    endif ()
    TPA_set(${_property}_OVERWRITE ${IN_OVERWRITE})
endfunction()

##############################################################################
# @brief Parse the input arguments previously defined by
# `doxypress_param_string`, `doxypress_param_option`, and
# `doxypress_param_list`.
# @param[in] ARGN input arguments
##############################################################################
function(doxypress_params_parse)
    TPA_get("option_args" _option_args)
    TPA_get("one_value_args" _one_value_args)
    TPA_get("multi_value_args" _multi_value_args)

    cmake_parse_arguments(DOXYPRESS
            "${_option_args}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    foreach (_option ${_option_args})
        doxypress_params_update(${_option} "${DOXYPRESS_${_option}}")
    endforeach ()
    foreach (_arg ${_one_value_args})
        doxypress_params_update(${_arg} "${DOXYPRESS_${_arg}}")
    endforeach ()
    foreach (_list ${_multi_value_args})
        doxypress_params_update(${_list} "${DOXYPRESS_${_list}}")
    endforeach ()

    # save explicitly given input arguments so that we can correctly handle
    # overrides later
    foreach(_arg ${ARGN})
        if (${_arg} IN_LIST _option_args)
            TPA_append(${_DOXYPRESS_INPUTS} ${_arg})
        endif()
        if (${_arg} IN_LIST _one_value_args)
            TPA_append(${_DOXYPRESS_INPUTS} ${_arg})
        endif()
        if (${_arg} IN_LIST _multi_value_args)
            TPA_append(${_DOXYPRESS_INPUTS} ${_arg})
        endif()
    endforeach()
endfunction()

##############################################################################
# @brief Calculates the value of an input parameter that is not referenced by
# JSON project file.
# @param[in] _name      parameter's name
# @param[in] _value     parameter's value in the input arguments
##############################################################################
function(doxypress_params_update _name _value)
    TPA_get("${_name}_UPDATER" _updater)
    TPA_get("${_name}_SETTER" _setter)
    TPA_get("${_name}_DEFAULT" _default)

    # convert CMake booleans to JSON's
    if ("${_value}" STREQUAL "TRUE")
        set(_value true)
    endif()
    if ("${_value}" STREQUAL "FALSE")
        set(_value false)
    endif()

    if (_value STREQUAL "")
        if (_setter)
            doxypress_call(doxypress_${_setter} _value)
        endif ()
        if (NOT _value STREQUAL "")
            if (_updater)
                doxypress_call(doxypress_${_updater} "${_value}" _value)
            endif ()
        endif ()
        if (_value STREQUAL "")
            # if no default, nothing happens
            if (NOT _default STREQUAL "")
                set(_value "${_default}")
            endif ()
        endif ()
    else ()
        if (_updater)
            doxypress_call(doxypress_${_updater} "${_value}" _value)
        endif ()
    endif ()
    doxypress_log(DEBUG "[input] ${_name} = ${_value}")
    TPA_set(${_name} "${_value}")
endfunction()

##############################################################################
## @brief Calls a function or a macro given its name. Writes actual call code
## into a temporary file, which is then included.
## @param[in] _id         name of the function or macro to call
## @param[in] _arg1       the first argument to `_id`
## @param[in] ARGN        arguments to pass to the callable `_id`
##############################################################################
macro(doxypress_call _id _arg1)
    if (NOT COMMAND ${_id})
        message(FATAL_ERROR "Unsupported function/macro \"${_id}\"")
    else ()
        set(_helper "${CMAKE_BINARY_DIR}/helpers/macro_helper_${_id}.cmake")
        # todo get this back?
        #if (NOT EXISTS "${_helper}")
        if ("${_arg1}" MATCHES "^\"(.*)\"$")
            file(WRITE "${_helper}" "${_id}(${_arg1} ${ARGN})\n")
        else()
            file(WRITE "${_helper}" "${_id}(\"${_arg1}\" ${ARGN})\n")
        endif()
        #foreach(_arg ${ARGN})
        #    file(APPEND "${_helper}" "\"${_arg}\" ")
        #endforeach()
        #file(APPEND "${_helper}" ")\n")
        #endif ()
        include("${_helper}")
    endif ()
endmacro()

function(doxypress_set_input_target _out_var)
    if (TARGET ${PROJECT_NAME})
        set(${_out_var} ${PROJECT_NAME} PARENT_SCOPE)
    else()
        set(${_out_var} "" PARENT_SCOPE)
    endif()
endfunction()
