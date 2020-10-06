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
    TPA_get(${_property}_INPUT _input_arg_name)
    TPA_get(${_property}_OVERWRITE _overwrite)
    TPA_get(${_property}_SETTER _setter)
    TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_DEFAULT _default)

    set(_value "")

    if (_input_arg_name)
        _doxypress_property_read_input(${_property} ${_input_arg_name} _input_value)
        set(_value ${_input_value})
    endif ()

    _doxypress_property_read_json(${_property} "${_value}" _value)

    # now, _value is either an input argument or a JSON value (or an empty
    # string)
    if (_setter)
        _doxypress_property_apply_setter(${_property} ${_setter} ${_overwrite} "${_value}" _value)
    endif()
    _doxypress_property_merge(${_property} "${_value}" "${_input_value}" _value)
    if (_updater)
        _doxypress_property_apply_updater(${_property} ${_updater} "${_value}" _value)
    endif()
    if (_default)
        _doxypress_property_apply_default(${_property} "${_default}" "${_value}" _value)
    endif()

    # apply overrides
    _doxypress_log(DEBUG "before overrides: ${_value}")
    _doxypress_property_override(${_property} _value)
    _doxypress_log(DEBUG "after overrides: ${_value}")
    _JSON_set(doxypress.${_property} "${_value}")
    _doxypress_log(DEBUG "${_property} = ${_value}")
    if (_input_arg_name)
        TPA_set(${_input_arg_name} "${_value}")
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
function(_doxypress_property_override _property _out_var)
    # search for an override
    TPA_get(properties _properties)
    TPA_get(${_DOXYPRESS_INPUTS} _inputs)

    set(_found false)
    if (${_property}_INPUT IN_LIST _properties)
        TPA_get(${_property}_INPUT _input_parameter)
        if (${_input_parameter} IN_LIST _inputs)
            set(_found true)
        endif()
    endif()

    if (NOT _found)
        if (NOT "${_property}" STREQUAL "${_DOXYPRESS_INPUT_SOURCE}")
            if (DEFINED ${_property})
                set(_message "CMake override ${_property} found:")
                _doxypress_log(DEBUG "${_message} ${${_property}}")
                set(${_out_var} "${${_property}}" PARENT_SCOPE)
            endif()
        endif ()
    else()
        # todo a better message
        _doxypress_log(WARN "Won't override ${_property}")
    endif()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_property_apply_setters
#
# .. code-block:: cmake
#
#   _doxypress_property_apply_setters(<JSON path> <output variable>)
#
# Helper function that handles `setter` -> `updater` -> `default` part of the
# property update logic.
#
# Parameters:
#
# * ``_property`` a property to update, specified by its JSON path
# * ``_out_var`` the output variable
##############################################################################
function(_doxypress_property_apply_setters _property _out_var)
    TPA_get(${_property}_SETTER _setter)
    # TPA_get(${_property}_UPDATER _updater)
    TPA_get(${_property}_DEFAULT _default)

    set(_value "")
    if (_setter)
        _doxypress_log(DEBUG "call setter ${_setter}")
        _doxypress_action(${_property} setter "${_value}")
        _doxypress_call(_doxypress_${_setter} _value)
    endif ()
    if (_updater)
        _doxypress_log(DEBUG "call updater ${_updater}")
        _doxypress_action(${_property} updater "${_value}")
        _doxypress_call(_doxypress_${_updater} "${_value}" _value)
    endif ()
    if (_value STREQUAL "")
        # if no default, _value is left empty
        if (NOT _default STREQUAL "")
            set(_value "${_default}")
            _doxypress_action(${_property} default "${_value}")
            _doxypress_log(DEBUG "[default] ${_property} = ${_default}")
        endif ()
    endif ()
    set(${_out_var} ${_value} PARENT_SCOPE)
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
# Helper function that handles `merge` -> `update` part of the property update
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
function(_doxypress_property_merge _property _value _input_value _out_var)
    # if it's an array and input was non-empty, merge the two
    # _doxypress_merge_lists()
    TPA_get(doxypress.${_property} _json_value)
    if (NOT _input_value STREQUAL "" AND "${_json_value}" MATCHES "^([0-9]+;)*([0-9]+)$")
        _JSON_get(doxypress.${_property} _json_value)
        foreach (_val ${_value})
            list(APPEND _json_value "${_val}")
        endforeach ()
        set(_value ${_json_value})
        _doxypress_action(${_property} merge "${_value}")
    endif ()

    #if (_updater)
    #    _doxypress_call(_doxypress_${_updater} "${_value}" _value)
    #endif ()
    set(${_out_var} ${_value} PARENT_SCOPE)
endfunction()

function(_doxypress_property_apply_setter _property _name _overwrite _value _out_var)
    if (_value STREQUAL "" OR _overwrite)
        # call setter
        _doxypress_log(DEBUG "call setter ${_name}")
        _doxypress_call(_doxypress_${_name} "${_value}" _new_value)
        _doxypress_action(${_property} setter "${_new_value}")
        set(${_out_var} ${_new_value} PARENT_SCOPE)
    endif()
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

function(_doxypress_property_read_input _property _input_arg_name _out_var)
    _doxypress_get_input_value(${_input_arg_name} _input_value)
    if (NOT _input_value STREQUAL "")
        _doxypress_action(${_property} input "${_input_value}")
        set(${_out_var} "${_input_value}" PARENT_SCOPE)
    endif()
endfunction()

function(_doxypress_property_read_json _property _value _out_var)
    if (_value STREQUAL "")
        _JSON_get(doxypress.${_property} _json_value)
        _doxypress_action(${_property} source "${_json_value}")
        set(${_out_var} "${_json_value}" PARENT_SCOPE)
    endif ()
endfunction()