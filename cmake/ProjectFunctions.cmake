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
    TPA_get(${_property}_OVERWRITE _overwrite)

    if (_input_param)
        _doxypress_property_read_input(${_property} ${_input_param} _input_value)
    endif ()
    # apply overrides
    _doxypress_property_override(${_property} _input_value)

    _doxypress_property_read_json(${_property} _json_value)

    set(_value "")
    if (_setter)
        if (_json_value STREQUAL "" AND _input_value STREQUAL "" OR _overwrite)
            _doxypress_property_apply_setter(${_property} ${_setter} _value)
        endif()
    endif()
    _doxypress_property_merge(${_property} "${_json_value}" "${_input_value}" _value)
    if (_updater)
        _doxypress_property_apply_updater(${_property} ${_updater} "${_value}" _value)
    endif()
    if (_default)
        _doxypress_property_apply_default(${_property} "${_default}" "${_value}" _value)
    endif()

    _JSON_set(doxypress.${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_param)
        TPA_set(${_input_param} "${_value}")
    endif ()
endfunction()

function(_doxypress_property_has_input _property _out_var)
    TPA_get(properties _properties)
    TPA_get(${_DOXYPRESS_INPUTS} _inputs)

    if (${_property}_INPUT IN_LIST _properties)
        TPA_get(${_property}_INPUT _input_parameter)
        if (${_input_parameter} IN_LIST _inputs)
            set(${_out_var} true PARENT_SCOPE)
            return()
        endif()
    endif()
    set(${_out_var} false PARENT_SCOPE)
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
function(_doxypress_property_override _property _out_var)
    # search for an override
    _doxypress_property_has_input(${_property} _found_input)

    if (NOT _found_input)
        if (DEFINED ${_property})
            set(_message "CMake override ${_property} found:")
            _doxypress_log(DEBUG "${_message} ${${_property}}")
            set(${_out_var} "${${_property}}" PARENT_SCOPE)
        endif()
    else()
        # todo a better message
        _doxypress_log(WARN "Won't override ${_property}")
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
    # _doxypress_merge_lists()
    TPA_get(doxypress.${_property} _json_value_raw)
    if (NOT _input_value STREQUAL "" AND "${_json_value_raw}" MATCHES "^([0-9]+;)*([0-9]+)$")
        # _JSON_get(doxypress.${_property} _json_value)
        _doxypress_log(DEBUG "_json_value = ${_json_value}")
        _doxypress_log(DEBUG "_input_value = ${_input_value}")
        foreach (_val ${_input_value})
            list(APPEND _json_value "${_val}")
        endforeach ()
        # set(_value ${_json_value})
        _doxypress_action(${_property} merge "${_json_value}")
    else()
        if (NOT _input_value STREQUAL "")
            set(_json_value "${_input_value}")
        endif()
    endif ()
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()

function(_doxypress_property_apply_setter _property _name _out_var)
    # call setter
    _doxypress_log(DEBUG "call setter ${_name}")
    _doxypress_call(_doxypress_${_name} _new_value)
    _doxypress_action(${_property} setter "${_new_value}")
    set(${_out_var} ${_new_value} PARENT_SCOPE)
endfunction()

function(_doxypress_property_apply_updater _property _name _value _out_var)
    # call updater
    _doxypress_log(DEBUG "call updater ${_name}(${_value})")
    _doxypress_call(_doxypress_${_name} "${_value}" _new_value)
    _doxypress_action(${_property} updater "${_new_value}")
    set(${_out_var} "${_new_value}" PARENT_SCOPE)
endfunction()

function(_doxypress_property_apply_default _property _default _value _out_var)
    if (_value STREQUAL "")
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
# * ``_property`` a property being processed
# * ``_input_arg_name`` an input parameter to read
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_property_read_input _property _input_arg_name _out_var)
    # _doxypress_get_input_value(${_input_arg_name} _input_value)
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
endfunction()

function(_doxypress_property_read_json _property _out_var)
    _JSON_get(doxypress.${_property} _json_value)
    if (NOT _json_value STREQUAL "")
        _doxypress_action(${_property} source "${_json_value}")
    endif()
    set(${_out_var} "${_json_value}" PARENT_SCOPE)
endfunction()
