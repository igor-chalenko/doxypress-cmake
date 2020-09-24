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
# target that is used as scope for stateful data. It's possible to set, unset,
# or append to a target property using syntax similar to that of
# `set(variable value)`. A call to `TPA_create_scope` with a previously unused
# prefix creates a new scope; subsequent calls to `TPA` functions use this scope
# implicitly until yet another scope is created. The actual prefix is held in
# the variable `_doxypress_cmake_uuid` that should be defined in the outer
# scope. If the variable is not defined, the scope will have a fixed name
# "_properties".
##############################################################################

include(${doxypress_dir}/DoxypressCommon.cmake)

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Implements scope naming scheme. This function should not be used
# anywhere except in `TPA_create_scope`.
# @param[in]  _prefix         prefix of the scope name
# @param[out] _out_var        output variable
# @return scope name
##############################################################################
function(TPA_scope_name _prefix _out_var)
    set(${_out_var} "${_prefix}_properties" PARENT_SCOPE)
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Creates a new scope with a given name prefix. If a scope with such
# prefix already exists, simply returns the scope name. This function is meant
# to be called by other `TPA` functions repeatedly to obtain the right scope
# without additional checking.
# @param[in]  _prefix         new scope's name prefix
# @param[out] _out_var        output variable
# @return scope's name, either a new one or one that existed beforehand
##############################################################################
function(TPA_create_scope _prefix _out_var)
    TPA_scope_name(${_prefix} _scope_name)

    if (NOT TARGET ${_scope_name})
        add_library(${_scope_name} INTERFACE)
        doxypress_log(DEBUG "Created INTERFACE target ${_scope_name}")
    endif()
    set(${_out_var} "${_scope_name}" PARENT_SCOPE)
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Sets the given property to a new value.
# @param[in] _property     a property to modify
# @param[in] _value        _property's new value
##############################################################################
function(TPA_set _property _value)
    TPA_create_scope(${_doxypress_cmake_uuid} _scope)
    set_property(TARGET ${_scope} PROPERTY INTERFACE_${_property} "${_value}")
    TPA_append(properties ${_property})
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Unsets the given property.
# @param[in] _property     the property to unset
##############################################################################
function(TPA_unset _property)
    TPA_create_scope(${_doxypress_cmake_uuid} _scope)
    set_property(TARGET ${_scope} PROPERTY INTERFACE_${_property})
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Returns value of a given property.
# @param[in] _property     the property to unset
# @param[out] _out_var     output variable
# @return property's value if found; empty string otherwise
##############################################################################
function(TPA_get _property _out_var)
    TPA_create_scope(${_doxypress_cmake_uuid} _scope)
    if (NOT TARGET ${_scope})
        unset(${_out_var} PARENT_SCOPE)
    else ()
        get_target_property(_value ${_scope} INTERFACE_${_property})
        if ("${_value}" STREQUAL "_value-NOTFOUND")
            set(${_out_var} "" PARENT_SCOPE)
        else ()
            set(${_out_var} "${_value}" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Appends a given value to the existing property. The property is treated
# as a list. If the given property's doesn't exist, it's created and set to
# the given value.
#
# @param[in] _property     the property to update
# @param[in] _value        the value to append
##############################################################################
function(TPA_append _property _value)
    TPA_create_scope(${_doxypress_cmake_uuid} _scope)

    TPA_get(${_property} _current_value)
    list(APPEND _current_value "${_value}")

    # don't call TPA_set in order to avoid endless recursion
    set_property(
            TARGET ${_scope}
            PROPERTY INTERFACE_${_property}
            "${_current_value}"
    )
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Clears all properties previously set by calls to `TPA_set` and
# `TPA_append`.
##############################################################################
function(TPA_clear_scope)
    TPA_get(properties _properties)
    foreach(_property ${_properties})
        TPA_unset(${_property})
        doxypress_log(DEBUG "unset ${_property}...")
    endforeach()
    TPA_unset(properties)
endfunction()
