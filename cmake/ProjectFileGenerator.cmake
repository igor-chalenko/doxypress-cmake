##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# Project file generator
# ----------------------
# This module implements functions that merge property values from different
# sources into a project file that will be used by `DoxyPress` as input.
# These sources include:
#
# * Inputs of :cmake:command:`doxypress_add_docs`
#
#   These fall into two categories. The first one is the input parameters that
#   are not bound to any JSON paths. They are defined dynamically using
#   the functions :cmake:command:`_doxypress_input_string`,
#   :cmake:command:`_doxypress_input_option`, and
#   :cmake:command:`_doxypress_input_list`. The second category is the input
#   parameters that are bound to some JSON paths and thus may appear in
#   the final project file. Parameters from this category are handled
#   by :cmake:command:`_doxypress_property_add`.
#
# * Project file template
#
#   A property in a project file is identified by its JSON paths. It's then
#   possible to bind some processing
#   :cmake:command:`_doxypress_property_add` to that JSON path.
#
# .. _overrides-reference-label:
#
# * Overrides
#
#   These are defined via :cmake:command:`doxypress_override_add`. If an
#   override is defined for a certain property, that property in the final
#   project file will have the value of that override, with one exception.
#   It's not possible to have an override for a property that also has
#   input parameter bound to it.
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
# using this function are interpreted later by
# :cmake:command:`_doxypress_inputs_parse`. The following arguments are
# recognized:
#
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
#.rst:
# .. cmake:command:: _doxypress_inputs_parse
#
# Parses the input arguments previously defined by
# :cmake:command:`_doxypress_input_string`,
# :cmake:command:`_doxypress_input_option`, and
# :cmake:command:`_doxypress_input_list`. Applies any bound handlers, such as
# ``setter``, ``updater``, and ``default``, to every input argument.
##############################################################################
function(_doxypress_inputs_parse)
    TPA_get("option_args" _option_args)
    TPA_get("one_value_args" _one_value_args)
    TPA_get("multi_value_args" _multi_value_args)

    _doxypress_log(DEBUG "options = ${_option_args}")
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
    foreach (_arg ${ARGN})
        if (${_arg} IN_LIST _option_args)
            TPA_append(${_DOXYPRESS_INPUTS_KEY} ${_arg})
        endif ()
        if (${_arg} IN_LIST _one_value_args)
            TPA_append(${_DOXYPRESS_INPUTS_KEY} ${_arg})
        endif ()
        if (${_arg} IN_LIST _multi_value_args)
            TPA_append(${_DOXYPRESS_INPUTS_KEY} ${_arg})
        endif ()
    endforeach ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_inputs_update(_name _value)
#
# Updates value of an input parameter (not referenced by the project file),
# based on the logic defined by previous calls to the functions
# :cmake:command:`_doxypress_input_string`,
# :cmake:command:`_doxypress_input_option`, and
# :cmake:command:`_doxypress_input_list`.
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
    endif ()
    if ("${_value}" STREQUAL "FALSE")
        set(_value false)
    endif ()

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
#.rst:
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
#
# .. note::
#    ``_doxypress_property_add(_property)`` can be called more than once for
#    the same property. In this case, property's handlers will be merged by
#    adding the new ones and keeping the existing ones.
##############################################################################
function(_doxypress_property_add _property)
    TPA_get(${_DOXYPRESS_JSON_PATHS_KEY} _properties)
    TPA_index(_index)

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
    if (DEFINED IN_DEFAULT AND NOT ${_property}_DEFAULT IN_LIST _index)
        TPA_set(${_property}_DEFAULT ${IN_DEFAULT})
    endif ()
    if (DEFINED IN_SETTER)
        TPA_set(${_property}_SETTER ${IN_SETTER})
    endif ()
    if (DEFINED IN_UPDATER)
        TPA_set(${_property}_UPDATER ${IN_UPDATER})
    endif ()
    TPA_get(${_property}_OVERWRITE _prev_overwrite)
    if (_prev_overwrite STREQUAL "")
        TPA_set(${_property}_OVERWRITE ${IN_OVERWRITE})
    endif ()

    TPA_append(${_DOXYPRESS_JSON_PATHS_KEY} "${_property}")
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_update_path
#
# .. code-block::
#
#   _doxypress_update_path(<JSON path>)
#
# Applies update logic to a given property. The property is updated in the
# loaded JSON document and in the stored input parameter, if one is defined
# for this property. See :ref:`algorithm<Algorithm>` for a detailed description
# of actions taken by the function.
##############################################################################
function(_doxypress_update_path _property)
    TPA_get(${_property}_INPUT _input_param)
    TPA_get(${_property}_SETTER _setter)
    TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_DEFAULT _default)

    _doxypress_property_read_input("${_input_param}" _input_value)
    _doxypress_property_read_json(${_property} _json_value)

    set(_value "")
    _doxypress_property_apply_setter(${_property} "${_setter}" _value)
    _doxypress_property_merge(${_property}
            "${_json_value}" "${_input_value}" _value)

    _doxypress_property_apply_updater(${_property}
            "${_updater}"
            "${_value}"
            _value)
    _doxypress_property_apply_default(${_property}
            "${_default}"
            "${_value}"
            "${_input_value}"
            _value)

    _doxypress_set(${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_param)
        TPA_set(${_input_param} "${_value}")
    endif ()
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
    #TPA_get(doxypress.${_property} _json_value_raw)
    #TPA_get("doxypress.${_property}_0" _array_first_element)
    _JSON_array_length(doxypress.${_property} _array_length)
    if (NOT _input_value STREQUAL "" AND ${_array_length} GREATER -1)
        foreach (_val ${_input_value})
            list(APPEND _json_value "${_val}")
        endforeach ()
        if (_json_value AND _input_value)
            _doxypress_action(${_property} merge "${_json_value}")
        endif ()
    else ()
        if (NOT _input_value STREQUAL "")
            set(_json_value "${_input_value}")
        endif ()
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
            if (NOT _new_value STREQUAL "")
                _doxypress_action(${_property} setter "${_new_value}")
            endif ()
            set(${_out_var} ${_new_value} PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

function(_doxypress_property_apply_updater _property _name _value _out_var)
    if (_name)
        # call updater
        _doxypress_log(DEBUG "call updater ${_name}(${_value})")
        _doxypress_call(_doxypress_${_name} "${_value}" _new_value)
        if (NOT _new_value STREQUAL "")
            _doxypress_action(${_property} updater "${_new_value}")
        endif ()
        set(${_out_var} "${_new_value}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_apply_default
#
# .. code-block:: cmake
#
#   _doxypress_property_apply_default(<property>
#                                     <default value>
#                                     <current value>
#                                     <output variable>)
#
# Sets output variable to the value of ``_default``, if ``_value`` is empty.
# Does nothing otherwise.
#
# Parameters:
#
# * ``_property`` an input property
# * ``_default`` a value to set
# * ``_value`` an input property
# * ``_out_var`` the value of ``_property``
##############################################################################
function(_doxypress_property_apply_default _property
        _default _value _input_value _out_var)
    if (NOT _default STREQUAL "")
        TPA_get(${_property}_OVERWRITE _overwrite)
        if (NOT _input_value STREQUAL "")
            set(_overwrite false)
        endif ()
        if (_value STREQUAL "" OR _overwrite)
            _doxypress_action(${_property} default "${_default}")
            set(${_out_var} "${_default}" PARENT_SCOPE)
        endif ()
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
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_read_json
#
# .. code-block:: cmake
#
#   _doxypress_property_read_json(<property> <output variable>)
#
# Returns the value of ``_property`` in the currently loaded JSON document.
#
# Parameters:
#
# * ``_property`` an input property
# * ``_out_var`` the value of ``_property``
##############################################################################
function(_doxypress_property_read_json _property _out_var)
    _doxypress_get("${_property}" _json_value)
    if (NOT _json_value STREQUAL "")
        _doxypress_action(${_property} source "${_json_value}")
    endif ()
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()
