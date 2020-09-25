##############################################################################
## @brief Specifies whether debug output should be produced by `doxypress_log`.
## If enabled,
## @code
## doxypress_log(DEBUG text) <==> message(STATUS text)
## @endcode
## If disabled, DEBUG messages are not printed.
##############################################################################
option(DOXYPRESS_DEBUG "Enable debug output." OFF)
##############################################################################
## @brief Specifies whether debug output should be produced by `doxypress_log`.
## If enabled,
## @code
## doxypress_log(INFO text) <==> message(STATUS text)
## @endcode
## If disabled, neither INFO not DEBUG messages are not printed.
##############################################################################
option(DOXYPRESS_INFO "Enable info output" OFF)


##############################################################################
## @brief Prints a given message if a corresponding log level is on (enabled
## by `DOXYPRESS_DEBUG` and `DOXYPRESS_INFO`). Does nothing otherwise.
##############################################################################
option(DOXYPRESS_DEBUG "Enable debug output." OFF)
option(DOXYPRESS_INFO "Enable info output" OFF)

## @brief Platform-specific executable for file opening
if (WIN32)
    set(DOXYPRESS_LAUNCHER_COMMAND start)
elseif (NOT APPLE)
    set(DOXYPRESS_LAUNCHER_COMMAND xdg-open)
endif ()

##############################################################################
## @brief Prints a given message if a corresponding log level is on (enabled
## by `DOXYPRESS_DEBUG` and `DOXYPRESS_INFO`). Does nothing otherwise.
##############################################################################
function(doxypress_log _level _text)
    if (_level STREQUAL INFO)
        set(_level "INFO ")
    endif()
    if (${DOXYPRESS_DEBUG})
        message(STATUS "[${_level}] ${_text}")
    endif ()
    if (${DOXYPRESS_INFO} AND NOT ${_level} STREQUAL DEBUG)
        message(STATUS "[${_level}] ${_text}")
    endif()
endfunction()

function(doxypress_cut_prefix _var _out_var)
    string(FIND ${_var} "." _ind)
    math(EXPR _ind "${_ind} + 1")
    string(SUBSTRING ${_var} ${_ind} -1 _cut_var)
    set(${_out_var} ${_cut_var} PARENT_SCOPE)
endfunction()
