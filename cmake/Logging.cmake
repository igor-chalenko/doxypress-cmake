##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# =======
# Logging
# =======
#
# This module implements basic logging with level limited by
# :cmake:variable:`DOXYPRESS_LOG_LEVEL`. There's also a function
# :cmake:command:`_doxypress_action`, which tracks property updates on
# a per-property basis, so that all updates to a single property can
# be examined.
##############################################################################

unset(_doxypress_log_levels)
list(APPEND _doxypress_log_levels DEBUG)
list(APPEND _doxypress_log_levels INFO)
list(APPEND _doxypress_log_levels WARN)

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_log
#
# .. code-block:: cmake
#
#    _doxypress_log(<level> <message>)
#
# Prints a given message if the corresponding log level is on (set by
# :cmake:variable:`DOXYPRESS_LOG_LEVEL`). Does nothing otherwise.
##############################################################################
function(_doxypress_log _level _text)
    list(FIND _doxypress_log_levels ${_level} _ind)
    if (_ind EQUAL -1)
        set(_ind 2)
    endif()
    list(FIND _doxypress_log_levels ${DOXYPRESS_LOG_LEVEL} _ind2)
    if (_ind2 EQUAL -1)
        set(_ind2 1)
    endif()
    if (${_ind} GREATER_EQUAL ${_ind2})
        if (${_level} STREQUAL WARN AND DOXYPRESS_PROMOTE_WARNINGS)
            message(WARNING "${_text}")
        else()
            message(STATUS "[${_level}] ${_text}")
        endif()
    endif ()
endfunction()

##############################################################################
#.rst:
#
# .. cmake:command:: _doxypress_action(<property> <action> <value>)
#
# Adds a record into the action log of a given property. Action log is helpful
# during debugging phase: it stores all updates to a given property in
# historical order. If a property has an incorrect value after processing,
# that property's log could be consulted to quickly find approximate location
# of an error.
##############################################################################
function(_doxypress_action _property _action _value)
    set(_message "")
    if ("${_value}" STREQUAL "")
        set(_value "<<empty>>")
    endif ()
    set(_message "[${_action}] ${_value}")
    TPA_get("histories" _histories)
    TPA_append("history.${_property}" "${_message}")

    if (NOT ${_property} IN_LIST _histories)
        TPA_append("histories" ${_property})
    endif ()
    _doxypress_log(DEBUG "[${_action}] ${_property} -> ${_value}")
endfunction()