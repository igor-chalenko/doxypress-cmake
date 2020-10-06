##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
#
# Doxypress parameters
# --------------------
#
# Input parameters to ``doxypress_add_docs`` are defined dynamically using
# the functions ``_doxypress_param_string``, ``_doxypress_param_option``,
# and ``_doxypress_param_list``. This dynamic definition enables declarative
# binding between parameters and their handlers. These declarations are then
# interpreted by the code that is does not depend on any specific parameter.
##############################################################################

unset(IN_INPUT_STRING)
unset(IN_INPUT_OPTION)
unset(IN_INPUT_LIST)
unset(IN_DEFAULT)
unset(IN_SETTER)
unset(IN_UPDATER)
unset(IN_OVERWRITE)

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_param_option
#
#  ..  code-block:: cmake
#
#    _doxypress_param_option(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input option. Declarations made
# using this function are interpreted later by ``_doxypress_params_parse``.
# The following arguments are recognized:
# * ``DEFAULT``
#
#   If the input option was not set in either ``ARGN``, setter, or updater,
#   it is set to this value.
#
# * ``SETTER``
#
#   A function with this name is called if the input option's value is
#   empty. The setter's output variable holds the option's new value.
#
# * ``UPDATER``
#
#   A function with this name is called if the current value of the option
#   is not empty. The current value is given as an argument. The output variable
#   holds the option's new value.
##############################################################################
function(_doxypress_param_option _name)
    set(_options "")
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("option_args" _option_args)
    list(APPEND _option_args ${_name})
    TPA_set("option_args" "${_option_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${_name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${_name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${_name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_param_string
#
#  ..  code-block:: cmake
#
#    _doxypress_param_string(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input single-value parameter.
# Declarations made using this function are interpreted later by
# ``_doxypress_params_parse``. The following arguments are recognized:
# * ``DEFAULT``
#
#   If the input multi-value parameter was not set in either ``ARGN``, setter,
#   or updater, it is set to this value.
#
# * ``SETTER``
#
#   A function with this name is called if the input parameter's value is
#   empty. The setter's output variable holds the parameter's new value.
#
# * ``UPDATER``
#
#   A function with this name is called if the current value of the parameter
#   is not empty. The current value is given as an argument. The output variable
#   holds the parameter's new value.
##############################################################################
function(_doxypress_param_string _name)
    set(_options OVERWRITE)
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("one_value_args" _one_value_args)
    list(APPEND _one_value_args ${_name})
    TPA_set("one_value_args" "${_one_value_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${_name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${_name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${_name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_param_list
#
#  ..  code-block:: cmake
#
#    _doxypress_param_list(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input multi-value parameter. Declarations
# made using this function are interpreted later by ``_doxypress_params_parse``.
# The following arguments are recognized:
# * ``DEFAULT``
#
#   If the input multi-value parameter was not set in either ``ARGN``, setter,
#   or updater, it is set to this value.
#
# * ``SETTER``
#
#   A function with this name is called if the input parameter's value is
#   empty. The setter's output variable holds the parameter's new value.
#
# * ``UPDATER``
#
#   A function with this name is called if the current value of the parameter
#   is not empty. The current value is given as an argument. The output variable
#   holds the parameter's new value.
##############################################################################
function(_doxypress_param_list _name)
    set(_options "")
    set(_one_value_args SETTER UPDATER DEFAULT)
    set(_multi_value_args "")
    cmake_parse_arguments(IN
            "${_options}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    TPA_get("multi_value_args" _multi_value_args)
    list(APPEND _multi_value_args ${_name})
    TPA_set("multi_value_args" "${_multi_value_args}")

    if (DEFINED IN_SETTER)
        TPA_set(${_name}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${_name}_UPDATER ${IN_UPDATER})
    endif ()
    if (DEFINED IN_DEFAULT)
        TPA_set(${_name}_DEFAULT ${IN_DEFAULT})
    endif ()
endfunction()

##############################################################################
# .rst:
# .. cmake:command:: _doxypress_json_property
#
#  ..  code-block:: cmake
#
#    _doxypress_json_property(<property>
#                 [INPUT_OPTION <name>]
#                 [INPUT_STRING <name>]
#                 [INPUT_LIST <name>]
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>]
#                 [USE_PRODUCT_NAME]
#                 [OVERWRITE])
#
# Attaches read/write logic to a given JSON path. Declarations made
# using this function are interpreted later by ``_doxypress_parse``.
# The following arguments are recognized:
#
# * ``INPUT_OPTION``, ``INPUT_STRING``, ``INPUT_LIST``
#
#   This JSON path can be updated if an input argument specified by one of
#   these options is provided. For example, `INPUT_OPTION GENERATE_XML`
#   specifies that `GENERATE_XML` is a valid argument of `doxypress_add_docs`.
#   If given, it will overwrite an existing value at the corresponding JSON
#   path; otherwise other handlers are invoked.
#
# * ``DEFAULT``
#
#   If the value in input JSON is empty, and no other handlers set it either,
#   this value is put into JSON path.
#
# * ``SETTER``
#
#   A function with this name is called if the current property value is empty.
#   The output variable becomes the new value in JSON.
#
# * ``UPDATER``
#
#   A function with this name is called if the current value of the property
#   is not empty. the current value is given as an argument. The output variable
#   becomes the new value in JSON.
#
# * ``OVERWRITE``
#
#   If given, the value in JSON is ignored and a given setter is called if
#   it was specified by `SETTER` argument. In other words, makes a call to
#   setter unconditional.
#
# The input arguments are parsed and stored in the current :ref:`TPA scope`.
##############################################################################
function(_doxypress_json_property _property)
    set(_options OVERWRITE)
    set(_one_value_args INPUT_OPTION INPUT_STRING DEFAULT SETTER UPDATER)
    set(_multi_value_args INPUT_LIST)

    cmake_parse_arguments(IN "${_options}" "${_one_value_args}"
            "${_multi_value_args}" "${ARGN}")

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

    TPA_append(${_DOXYPRESS_JSON_PATHS_KEY} ${_property})
endfunction()

##############################################################################
# .rst:
# .. cmake:command:: _doxypress_params_parse
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
# Parses the input arguments previously defined by
# :ref:`_doxypress_param_string`, :ref:`_doxypress_param_option`, and
# :ref:`_doxypress_param_list`.
##############################################################################
function(_doxypress_params_parse)
    TPA_get("option_args" _option_args)
    TPA_get("one_value_args" _one_value_args)
    TPA_get("multi_value_args" _multi_value_args)

    cmake_parse_arguments(DOXYPRESS
            "${_option_args}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    foreach (_option ${_option_args})
        _doxypress_params_update(${_option} "${DOXYPRESS_${_option}}")
    endforeach ()
    foreach (_arg ${_one_value_args})
        _doxypress_params_update(${_arg} "${DOXYPRESS_${_arg}}")
    endforeach ()
    foreach (_list ${_multi_value_args})
        _doxypress_params_update(${_list} "${DOXYPRESS_${_list}}")
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
# .rst:
# .. cmake:command:: _doxypress_params_update(_name _value)
#
# Updates value of an input parameter (not referenced by the project file),
# based on the logic defined by previous calls to the functions
# ``doxypress_param_*``.
#
# Parameters:
#
# * ``_name``  parameter's name
# * ``_value`` parameter's value after applying setter, updater, and defaults
##############################################################################
function(_doxypress_params_update _name _value)
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
            _doxypress_call(_doxypress_${_setter} _value)
        endif ()
        if (NOT _value STREQUAL "")
            if (_updater)
                _doxypress_call(_doxypress_${_updater} "${_value}" _value)
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
            _doxypress_call(_doxypress_${_updater} "${_value}" _value)
        endif ()
    endif ()
    _doxypress_log(DEBUG "[input] ${_name} = ${_value}")
    TPA_set(${_name} "${_value}")
endfunction()

##############################################################################
# @brief Calls a function or a macro given its name. Writes actual call code
# into a temporary file, which is then included.
# @param[in] _id         name of the function or macro to call
# @param[in] _arg1       the first argument to `_id`
# @param[in] ARGN        arguments to pass to the callable `_id`
##############################################################################
macro(_doxypress_call _id _arg1)
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
