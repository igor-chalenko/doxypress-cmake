## ----------------------------------------------------------------------------
## @brief Choose whether debug output should be produced by `doxypress_add_docs`
## and its nested functions/macros. If enabled,
## @code
## doxypress_log(text) <==> message(STATUS text)
## @endcode
## If disabled, `doxypress_log(text)` doesn't do anything.
## ----------------------------------------------------------------------------
option(DOXYPRESS_DEBUG "Enable debug output." OFF)
option(DOXYPRESS_INFO "Enable info output" OFF)


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
