##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
# @file TargetPropertyAccess.cmake
# @brief Contains functions that simplify access to target properties.
# @author Igor Chalenko
##############################################################################

##############################################################################
# @defgroup TargetPropertyAccess Simplified access to target properties
# @brief Functions with prefix `TPA` manage state of a surrogate `INTERFACE`
# target that is used as a scope for stateful part of the data being worked
# with. It's possible to set, unset, or append to a target property using syntax
# similar to that of `set(variable value)`.
##############################################################################

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Sets the given variable to the name of properties' CMake target.
# @param[out] _out_var        property's new value
##############################################################################
function(TPA_scope_name _out_var)
    set(${_out_var} "properties_properties" PARENT_SCOPE)
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Sets the given property to a new value.
# @param[in] _name         property to set
# @param[in] _value        property's new value
##############################################################################
function(TPA_set _name _value)
    TPA_scope_name(_arguments_target)
    if (NOT TARGET ${_arguments_target})
        doxypress_log(DEBUG "Created target ${_arguments_target}")
        add_library(${_arguments_target} INTERFACE)
    endif ()
    set_property(
            TARGET ${_arguments_target}
            PROPERTY INTERFACE_${_name}
            ${_value})
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Unsets the given property.
# @param[in] _property     the property to unset
##############################################################################
function(TPA_unset _property)
    TPA_scope_name(_arguments_target)
    set_property(TARGET ${_arguments_target} PROPERTY INTERFACE_${_property})
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Unsets the given property.
# @param[in] _name     the property to unset
# @param[out] _out_var result variable
# @return property's value if found; empty string otherwise
##############################################################################
function(TPA_get _name _out_var)
    TPA_scope_name(_arguments_target)
    if (NOT TARGET ${_arguments_target})
        unset(${_out_var} PARENT_SCOPE)
    else ()
        get_target_property(_property ${_arguments_target} INTERFACE_${_name})
        if ("${_property}" STREQUAL "_property-NOTFOUND")
            set(${_out_var} "" PARENT_SCOPE)
        else ()
            set(${_out_var} "${_property}" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()


##############################################################################
# @ingroup TargetPropertyAccess
# @brief Appends given value to the existing property's list of values. If
# the property's value is empty, the given value becomes the first one in the
# list.
#
# @param[in] _property     the property to extend
# @param[in] _value        the value to append to `_property`
##############################################################################
function(TPA_append _property _value)
    TPA_get(${_property} _properties)
    list(APPEND _properties "${_value}")
    TPA_set(${_property} "${_properties}")
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Clears all properties previously set by calls to `TPA_set()`.
##############################################################################
function(TPA_clear_scope)
    TPA_get(properties _properties)
    foreach(_property ${_properties})
        TPA_unset(${_property}_DEFAULT)
        TPA_unset(${_property}_SETTER)
        TPA_unset(${_property}_UPDATER)
        TPA_unset(${_property}_OVERWRITE)
        TPA_unset(${_property}_INPUT)
        TPA_unset(doxypress.${_property})
        doxypress_log(DEBUG "unset ${_property}...")
    endforeach()
    TPA_unset(properties)

    TPA_get("option_args" _option_args)
    foreach(_arg ${_option_args})
        TPA_unset(${_arg})
    endforeach()
    TPA_get("one_value_args" _one_value_args)
    foreach(_arg ${_one_value_args})
        TPA_unset(${_arg})
    endforeach()
    TPA_get("multi_value_args" _multi_value_args)
    foreach(_arg ${_multi_value_args})
        TPA_unset(${_arg})
    endforeach()
    TPA_unset(option_args)
    TPA_unset(one_value_args)
    TPA_unset(multi_value_args)
endfunction()
