##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# Target Property Accessors (TPA)
# -------------------------------
#
# Functions with prefix ``TPA`` manage state a surrogate `INTERFACE` target:
# properties of this targets are used as global cache for stateful data.
# This surrogate target is called `TPA scope` throughout this document.
# It's possible to set, unset, or append to a target property using syntax
# similar to that of usual variables:
#
# .. code-block:: cmake
#
#   # set(variable value)
#   TPA_set(variable value)
#   # unset(variable)
#   TPA_unset(variable)
#   # list(APPEND variable value)
#   TPA_append(variable value)
#
# ---------
# TPA scope
# ---------
#
# TPA scope is a dictionary of some target's properties. Therefore, it is
# a named global scope with a lifetime of the underlying target. Variables never
# go out of scope in `TPA` and must be deleted explicitly (if needed). `CMake`
# doesn't allow arbitrary property names; therefore, input property names are
# prefixed with ``INTERFACE_`` to obtain the actual property name in that
# `INTERFACE` target. Each TPA scope maintains index of properties
# it contains; this makes it easy to clear up a scope entirely and re-use it
# afterwards. There could be as many different TPA scopes as there are different
# values of the ``CMAKE_CURRENT_SOURCE_DIR`` variable. Therefore, it's safe
# to run parallel builds as long as there is only one CMake process working
# on a given directory.

include(${doxypress_dir}/Logging.cmake)

##############################################################################
#.rst:
# -------------
# TPA functions
# -------------
##############################################################################

##############################################################################
#.rst:
# .. cmake:command:: TPA_set(_property _value)
#
# Sets the given property to a new value.
#
# Parameters:
#
# * ``_property``     a property to modify
# * ``_value``        _property's new value
##############################################################################
function(TPA_set _property _value)
    _TPA_current_scope(_scope)
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
#.rst:
# .. cmake:command:: TPA_unset(_property)
#
# Unsets the property given by ``_property``.
#
# Parameters:
#
# * ``_property`` a property to unset
##############################################################################
function(TPA_unset _property)
    _TPA_current_scope(_scope)
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
#.rst:
# .. cmake:command:: TPA_get(_property _out_var)
#
# Returns the value of a given property.
#
# Parameters:
#
# * ``_property`` the property to unset
# * ``_out_var``  the property's value if found; empty string otherwise
##############################################################################
function(TPA_get _property _out_var)
    _TPA_current_scope(_scope)
    get_target_property(_value ${_scope} INTERFACE_${_property})
    if ("${_value}" STREQUAL "_value-NOTFOUND")
        set(${_out_var} "" PARENT_SCOPE)
    else ()
        set(${_out_var} "${_value}" PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: TPA_append(_property _value)
#
# If the property `_property` exists, it is treated as a list, and the given
# value is appended to it. Otherwise, it's created and set to the given value.
#
# Parameters:
#
# * ``_property``     the property to update
# * ``_value``        the value to append
##############################################################################
function(TPA_append _property _value)
    _TPA_current_scope(_scope)

    TPA_get(${_property} _current_value)
    if ("${_current_value}" STREQUAL "")
        TPA_set(${_property} "${_value}")
    else()
        # no need to update the index
        list(APPEND _current_value "${_value}")
        TPA_set(${_property} "${_current_value}")
    endif()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: TPA_clear_scope
#
# Clears all properties previously set by calls to `TPA_set` and `TPA_append`.
# Uses index variable ``properties`` to get the list of all properties.
##############################################################################
function(TPA_clear_scope)
    TPA_get(properties _properties)
    foreach(_property ${_properties})
        TPA_unset(${_property})
    endforeach()
    TPA_unset(properties)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _TPA_current_scope(_out_var)
#
# Defines what the current scope is. Upon first invocation in the current
# `CMake` source directory, creates an `INTERFACE` with a name derived
# from the value of the variable ``CMAKE_CURRENT_SOURCE_DIR``. Afterwards,
# this name is written into the output variable ``_out_var``. This function is
# used by other `TPA` functions to obtain the current scope; it's not meant
# to be used outside the module.
##############################################################################
function(_TPA_current_scope _out_var)
    _TPA_scope_name(_scope_name)

    if (NOT TARGET ${_scope_name})
        add_library(${_scope_name} INTERFACE)
        _doxypress_log(DEBUG "Created INTERFACE target ${_scope_name}")
    endif()
    set(${_out_var} "${_scope_name}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _TPA_scope_name(_out_var)
#
# Implements scope naming scheme. The current directory's name is transformed
# to satisfy requirements for valid target names, and then used as a prefix
# for the resulting name. This name is then written into ``_out_var``.
#
# This function should not be used anywhere except in `_TPA_current_scope`.
##############################################################################
function(_TPA_scope_name _out_var)
    string(REPLACE "/" "." _replaced "${CMAKE_CURRENT_SOURCE_DIR}")
    string(REPLACE "\\" "." _replaced "${_replaced}")
    set(${_out_var} "${_replaced}.properties" PARENT_SCOPE)
endfunction()

