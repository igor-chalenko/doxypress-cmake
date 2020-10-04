##############################################################################
## @brief Specifies whether debug output should be produced by `_doxypress_log`.
## If enabled,
## @code
## _doxypress_log(DEBUG text) <==> message(STATUS text)
## @endcode
## If disabled, DEBUG messages are not printed.
##############################################################################
option(DOXYPRESS_LOG_LEVEL "Enable log output above this level." INFO)
option(DOXYPRESS_PROMOTE_WARNINGS "Promote log warnings to CMake warnings" ON)

## @brief Platform-specific executable for file opening
if (WIN32)
    set(DOXYPRESS_LAUNCHER_COMMAND start)
elseif (NOT APPLE)
    set(DOXYPRESS_LAUNCHER_COMMAND xdg-open)
endif ()

unset(_doxypress_log_levels)
list(APPEND _doxypress_log_levels DEBUG)
list(APPEND _doxypress_log_levels INFO)
list(APPEND _doxypress_log_levels WARN)

function(_doxypress_log _level _text)
    list(FIND _doxypress_log_levels ${_level} _ind)
    if (_ind EQUAL -1)
        set(_ind 2)
    endif()
    list(FIND _doxypress_log_levels ${DOXYPRESS_LOG_LEVEL} _ind2)
    if (_ind2 EQUAL -1)
        set(_ind2 1)
    endif()
    # message(STATUS "${_ind}:${DOXYPRESS_LOG_LEVEL}")
    if (${_ind} GREATER_EQUAL ${_ind2})
        message(STATUS "[${_level}] ${_text}")
    endif ()
endfunction()

function(_doxypress_cut_prefix _var _out_var)
    string(FIND ${_var} "." _ind)
    math(EXPR _ind "${_ind} + 1")
    string(SUBSTRING ${_var} ${_ind} -1 _cut_var)
    set(${_out_var} ${_cut_var} PARENT_SCOPE)
endfunction()
