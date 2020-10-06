##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
#
# Common functions and variables
# ------------------------------
##############################################################################

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_LOG_LEVEL
#
# Controls output produced by `_doxypress_log`.
#
# .. code-block:: cmake
#
#    # DOXYPRESS_LOG_LEVEL = DEBUG
#    _doxypress_log(DEBUG text) # equivalent to message(STATUS text)
#    _doxypress_log(INFO text) # equivalent to message(STATUS text)
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYPRESS_LOG_LEVEL = INFO
#    _doxypress_log(DEBUG text) # does nothing
#    _doxypress_log(INFO text) # equivalent to message(STATUS text)
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYPRESS_LOG_LEVEL = WARN
#    _doxypress_log(DEBUG text) # does nothing
#    _doxypress_log(INFO text) # does nothing
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
##############################################################################
set(DOXYPRESS_LOG_LEVEL INFO)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_PROMOTE_WARNINGS
#
# Specifies what message level ``_doxypress_log(WARN text)`` should use.
#
# .. code-block:: cmake
#
#    # DOXYPRESS_PROMOTE_WARNINGS = ON
#    _doxypress_log(WARN text) # equivalent to message(WARNING text)
#    # DOXYPRESS_PROMOTE_WARNINGS = OFF
#    _doxypress_log(WARN text) # equivalent to message(STATUS text)
#
##############################################################################
option(DOXYPRESS_PROMOTE_WARNINGS "Promote log warnings to CMake warnings" ON)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYPRESS_LAUNCHER_COMMAND
#
# Platform-specific executable for file opening:
#
# * ``start`` on Windows
# * ``open`` on OS/X
# * ``xdg-open`` on Linux
##############################################################################
if (WIN32)
    set(DOXYPRESS_LAUNCHER_COMMAND start)
elseif (NOT APPLE)
    set(DOXYPRESS_LAUNCHER_COMMAND xdg-open)
else()
    # I didn't test this
    set(DOXYPRESS_LAUNCHER_COMMAND open)
endif ()

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
# :cmake:variable:`DOXYPRESS_LOG_LEVEL`). Does nothing
# otherwise.
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
# todo better messages ?
##############################################################################
function(_doxypress_action _property _action _value)
    set(_message "")
    if ("${_value}" STREQUAL "")
        set(_value "<<empty>>")
    endif ()
    if (${_action} STREQUAL setter)
        set(_message "[setter] ${_value}")
    elseif (${_action} STREQUAL updater)
        set(_message "[updater] ${_value}")
    elseif (${_action} STREQUAL default)
        set(_message "[default] ${_value}")
    elseif (${_action} STREQUAL source)
        set(_message "[source] ${_value}")
    elseif (${_action} STREQUAL input)
        set(_message "[input] ${_value}")
    elseif (${_action} STREQUAL merge)
        set(_message "[merged] ${_value}")
    endif ()
    TPA_get("histories" _histories)
    TPA_append("history.${_property}" "${_message}")

    if (NOT ${_property} IN_LIST _histories)
        TPA_append("histories" ${_property})
    endif ()
endfunction()