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
# or append to a target property using syntax similar to that of usual
# variables:
#
# * TPA_set(variable value) # set(variable value)
# * TPA_unset(variable) # unset(variable)
# * TPA_append(variable value) # list(APPEND variable value)
#
# A call to `TPA_create_scope` creates a new scope in every `CMake` source
# directory: the value of `${CMAKE_CURRENT_SOURCE_DIR}` is transformed to
# satisfy requirements put on target names, and then used as a prefix for
# a new target.
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
function(TPA_scope_name _out_var)
    string(REPLACE "/" "." _replaced "${CMAKE_CURRENT_SOURCE_DIR}")
    string(REPLACE "\\" "." _replaced "${_replaced}")
    set(${_out_var} "${_replaced}.properties" PARENT_SCOPE)
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
function(TPA_create_scope _out_var)
    TPA_scope_name(_scope_name)

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
    TPA_create_scope(_scope)
    set_property(TARGET ${_scope} PROPERTY INTERFACE_${_property} "${_value}")

    if (NOT ${_property} STREQUAL "properties")
        TPA_get(properties _properties)
        set(_flag false)
        foreach(_existing ${_properties})
            if (${_existing} STREQUAL ${_property})
                set(_flag true)
            endif()
        endforeach()
        if (NOT ${_flag})
            list(APPEND _properties ${_property})
            # set_property(TARGET ${_scope} PROPERTY properties "${_properties}")
            TPA_set(properties "${_properties}")
        endif()
    endif()
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Unsets the given property.
# @param[in] _property     the property to unset
##############################################################################
function(TPA_unset _property)
    TPA_create_scope(_scope)
    set_property(TARGET ${_scope} PROPERTY INTERFACE_${_property})

    TPA_get(properties _properties)
    foreach(_existing ${_properties})
        if (${_existing} STREQUAL ${_property})
            list(REMOVE_ITEM _properties ${_existing})
        endif()
    endforeach()
    TPA_set(properties "${_properties}")
endfunction()

##############################################################################
# @ingroup TargetPropertyAccess
# @brief Returns value of a given property.
# @param[in] _property     the property to unset
# @param[out] _out_var     output variable
# @return property's value if found; empty string otherwise
##############################################################################
function(TPA_get _property _out_var)
    TPA_create_scope(_scope)
    get_target_property(_value ${_scope} INTERFACE_${_property})
    if ("${_value}" STREQUAL "_value-NOTFOUND")
        set(${_out_var} "" PARENT_SCOPE)
    else ()
        set(${_out_var} "${_value}" PARENT_SCOPE)
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
    TPA_create_scope(_scope)

    TPA_get(${_property} _current_value)
    if ("${_current_value}" STREQUAL "")
        TPA_set(${_property} "${_value}")
    else()
        # no need to update the index
        list(APPEND _current_value "${_value}")

        # ???
        TPA_set(${_property} "${_current_value}")
        # don't call TPA_set in order to avoid endless recursion
        # set_property(
        #        TARGET ${_scope}
        #        PROPERTY INTERFACE_${_property}
        #        "${_current_value}"
        #)
    endif()
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
    endforeach()
    TPA_unset(properties)
endfunction()
