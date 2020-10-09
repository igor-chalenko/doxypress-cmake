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
# the functions ``_doxypress_input_string``, ``_doxypress_input_option``,
# and ``_doxypress_input_list``. This dynamic definition enables declarative
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
# .. cmake:command:: _doxypress_input_option
#
#  ..  code-block:: cmake
#
#    _doxypress_input_option(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input option. Declarations made
# using this function are interpreted later by ``_doxypress_inputs_parse``.
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
function(_doxypress_input_option _name)
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
# .. cmake:command:: _doxypress_input_string
#
#  ..  code-block:: cmake
#
#    _doxypress_input_string(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input single-value parameter.
# Declarations made using this function are interpreted later by
# ``_doxypress_inputs_parse``. The following arguments are recognized:
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
function(_doxypress_input_string _name)
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
# .. cmake:command:: _doxypress_input_list
#
#  ..  code-block:: cmake
#
#    _doxypress_input_list(<property>
#                 [SETTER <function name>]
#                 [UPDATER <function name>]
#                 [DEFAULT <value>])
#
# Attaches read/write logic to a given input multi-value parameter. Declarations
# made using this function are interpreted later by ``_doxypress_inputs_parse``.
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
function(_doxypress_input_list _name)
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
# .. cmake:command:: _doxypress_inputs_parse
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
# :ref:`_doxypress_input_string`, :ref:`_doxypress_input_option`, and
# :ref:`_doxypress_input_list`.
##############################################################################
function(_doxypress_inputs_parse)
    TPA_get("option_args" _option_args)
    TPA_get("one_value_args" _one_value_args)
    TPA_get("multi_value_args" _multi_value_args)

    cmake_parse_arguments(DOXYPRESS
            "${_option_args}"
            "${_one_value_args}"
            "${_multi_value_args}"
            "${ARGN}")

    foreach (_option ${_option_args})
        _doxypress_inputs_update(${_option} "${DOXYPRESS_${_option}}")
    endforeach ()
    foreach (_arg ${_one_value_args})
        _doxypress_inputs_update(${_arg} "${DOXYPRESS_${_arg}}")
    endforeach ()
    foreach (_list ${_multi_value_args})
        _doxypress_inputs_update(${_list} "${DOXYPRESS_${_list}}")
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
# .. cmake:command:: _doxypress_inputs_update(_name _value)
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
function(_doxypress_inputs_update _name _value)
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
# .rst:
# .. cmake:command:: _doxypress_property_add
#
#  ..  code-block:: cmake
#
#    _doxypress_property_add(<property>
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
function(_doxypress_property_add _property)
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

    TPA_append(${_DOXYPRESS_JSON_PATHS_KEY} "${_property}")
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_update
#
# ..code-block::
#
#   _doxypress_property_update(<JSON path>)
#
# Applies update logic to a given property. The property is updated in the
# loaded JSON document and in the stored input parameter, if one is defined
# for this property. See :ref:`algorithm<Algorithm>` for a detailed description
# of actions taken by the function.
##############################################################################
function(_doxypress_property_update _property)
    TPA_get(${_property}_INPUT _input_param)
    TPA_get(${_property}_SETTER _setter)
    TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_DEFAULT _default)

    _doxypress_property_read_input("${_input_param}" _input_value)
    _doxypress_property_override(${_property} "${_input_value}" _input_value)
    _doxypress_property_read_json(${_property} _json_value)

    set(_value "")
    _doxypress_property_apply_setter(${_property} "${_setter}" _value)
    _doxypress_property_merge(${_property}
            "${_json_value}" "${_input_value}" _value)

    _doxypress_property_apply_updater(${_property} "${_updater}" "${_value}" _value)
    _doxypress_property_apply_default(${_property} "${_default}" "${_value}" _value)

    _doxypress_set(${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_param)
        TPA_set(${_input_param} "${_value}")
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_override
#
# ..code-block::
#
#   _doxypress_property_override(<JSON path> <output variable>)
#
# Applies override logic to a given property. The override is defined for
# the property ``_property``, if there was a call
#
# .. code-block:: cmake
#
#   set(_property value)
#
# previously. If a property ``_property`` was specified in the input arguments,
# the override is not applied.
#
# Parameters:
#
# * ``_property`` a property to override
##############################################################################
function(_doxypress_property_override _property _input_value _out_var)
    # search for an override
    if (_input_value STREQUAL "")
        if (DEFINED ${_property})
            set(_message "CMake override ${_property} found:")
            _doxypress_log(DEBUG "${_message} ${${_property}}")
            set(${_out_var} "${${_property}}" PARENT_SCOPE)
        endif()
    endif()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_merge
#
# .. code-block:: cmake
#
#   _doxypress_property_merge(<JSON path>
#                            <value>
#                            <input argument>
#                            <output variable>)
#
# Helper function that handles `merge` part of the property update
# logic.
#
# .. note::
#
# This function can only handle JSON properties that have a value other
# than ``0``. If a property has a value of ``0``, it will be recognized
# as an array head (incorrectly). This is not a problem in the current
# implementation, as it only transforms string properties.
#
# Parameters:
#
# * ``_property`` a property to update, specified by its JSON path
# * ``_value`` the property's current value, read from JSON; could be empty
# * ``_input_value`` the value of ``_property`` from a corresponding input
#   parameter
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_property_merge _property _json_value _input_value _out_var)
    # if it's an array and input was non-empty, merge the two
    TPA_get(doxypress.${_property} _json_value_raw)
    if (NOT _input_value STREQUAL "" AND "${_json_value_raw}" MATCHES "^([0-9]+;)*([0-9]+)$")
        foreach (_val ${_input_value})
            list(APPEND _json_value "${_val}")
        endforeach ()
        _doxypress_action(${_property} merge "${_json_value}")
    else()
        if (NOT _input_value STREQUAL "")
            set(_json_value "${_input_value}")
        endif()
    endif ()
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()

function(_doxypress_property_apply_setter _property _name _out_var)
    if (_name)
        TPA_get(${_property}_OVERWRITE _overwrite)
        if (_json_value STREQUAL "" AND _input_value STREQUAL "" OR _overwrite)
            # call setter
            _doxypress_log(DEBUG "call setter ${_name}")
            _doxypress_call(_doxypress_${_name} _new_value)
            _doxypress_action(${_property} setter "${_new_value}")
            set(${_out_var} ${_new_value} PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(_doxypress_property_apply_updater _property _name _value _out_var)
    if (_name)
        # call updater
        _doxypress_log(DEBUG "call updater ${_name}(${_value})")
        _doxypress_call(_doxypress_${_name} "${_value}" _new_value)
        _doxypress_action(${_property} updater "${_new_value}")
        set(${_out_var} "${_new_value}" PARENT_SCOPE)
    endif()
endfunction()

function(_doxypress_property_apply_default _property _default _value _out_var)
    if (_value STREQUAL "" AND NOT _default STREQUAL "")
        _doxypress_action(${_property} default "${_default}")
        set(${_out_var} "${_default}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_read_input
#
# .. code-block:: cmake
#
#   _doxypress_property_read_input(<property> <argument name> <output variable>)
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
function(_doxypress_property_read_input _input_arg_name _out_var)
    if (_input_arg_name)
        TPA_get(${_input_arg_name} _input_value)

        if (NOT _input_value STREQUAL "")
            # convert CMake booleans to JSON's
            if (_input_value STREQUAL TRUE)
                set(_input_value true)
            elseif (_input_value STREQUAL FALSE)
                set(_input_value false)
            endif ()

            _doxypress_action(${_property} input "${_input_value}")
            set(${_out_var} "${_input_value}" PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(_doxypress_property_read_json _property _out_var)
    _doxypress_get("${_property}" _json_value)
    if (NOT _json_value STREQUAL "")
        _doxypress_action(${_property} source "${_json_value}")
    endif()
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()
