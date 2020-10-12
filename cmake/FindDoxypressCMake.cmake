##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

#.rst:
# FindDoxypress
# -------------
#
# This module looks for Doxypress_ and some optional tools it supports. These
# tools are enabled as components in the ``find_package`` command:
#
# * ``dot`` Graphviz dot utility used to render various graphs;
#
# * ``mscgen`` Message Chart Generator utility used by `DoxyPress`’ ``msc`` and
#   ``mscfile`` commands;
#
# * ``dia`` Dia the diagram editor used by `DoxyPress`' `diafile` command.
#
# .. _Doxypress: https://www.copperspice.com/docs/doxypress/index.html
#
# **Examples**
#
# .. code-block:: cmake
#
#    # Require dot, treat the other components as optional
#    find_package(Doxypress
#                 REQUIRED dot
#                 OPTIONAL_COMPONENTS mscgen dia)
#
# If `DoxyPress` was found, the following definitions are created:
#
# * The variable ``DOXYPRESS_FOUND`` is set to `YES` (it is set to `NO`
#   if `DoxyPress` was not found)
#
# * The variable ``DOXYPRESS_EXECUTABLE`` contains the full path to the found
#   executable
#
# * The variable ``DOXYPRESS_VERSION`` contains the version reported by
#
# .. code-block:: bash
#
#    doxypress --version
#
# * The `IMPORTED` target ``Doxypress::doxypress`` is created; it can be used in
#   custom commands like this:
#
# .. code-block:: cmake
#
#    add_custom_command(COMMAND Doxypress::doxypress ...)
#
# In addition to the above, for each requested AND found component the following
# definitions are created:
#
# * ``dot``
#
#   a. Variable ``DOXYPRESS_DOT_PATH``
#   b. Variable ``DOXYPRESS_DOT_EXECUTABLE``
#   c. Target ``Doxypress::dot``
#
# * ``dia``
#
#   a. Variable ``DOXYPRESS_DIA_PATH``
#   b. Variable ``DOXYPRESS_DIA_EXECUTABLE``
#   c. Target ``Doxypress::dia``
#
# * ``mscgen``
#
#   a. ``DOXYPRESS_MSCGEN_PATH``
#   b. ``DOXYPRESS_MSCGEN_EXECUTABLE``
#   c. Target ``Doxypress::mscgen``
#
# The component import targets will only be defined if that component was
# requested.
##############################################################################

include(FindPackageHandleStandardArgs)

# We must run the following at "include" time, not at function call time,
# to find the path to this module rather than the path to a calling list file
get_filename_component(doxypress_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

macro(_Doxypress_find_doxypress)
    find_program(
            DOXYPRESS_EXECUTABLE
            NAMES doxypress
            PATHS
            "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Doxypress: InstallLocation]"
            /Applications/Doxypress.app/Contents/Resources
            /Applications/Doxypress.app/Contents/MacOS
            /Applications/Utilities/Doxypress.app/Contents/Resources
            /Applications/Utilities/Doxypress.app/Contents/MacOS
            DOC "Doxypress - documentation generation tool (http://www.copperspice.com)"
    )
    mark_as_advanced(DOXYPRESS_EXECUTABLE)

    if (DOXYPRESS_EXECUTABLE)
        execute_process(
                COMMAND "${DOXYPRESS_EXECUTABLE}" --version
                OUTPUT_VARIABLE DOXYPRESS_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE
                RESULT_VARIABLE _Doxypress_version_result
        )
        if (_Doxypress_version_result)
            message(WARNING "Unable to determine doxypress version: ${_Doxypress_version_result}")
        else ()
            string(STRIP ${DOXYPRESS_VERSION} DOXYPRESS_VERSION)
            string(SUBSTRING ${DOXYPRESS_VERSION} 19 -1 DOXYPRESS_VERSION)
            string(FIND ${DOXYPRESS_VERSION} "\n" ind)
            string(SUBSTRING ${DOXYPRESS_VERSION} 0 ${ind} DOXYPRESS_VERSION)
        endif ()

        # Create an imported target for Doxygen
        if (NOT TARGET Doxypress::doxypress)
            add_executable(Doxypress::doxypress IMPORTED GLOBAL)
            set_target_properties(Doxypress::doxypress PROPERTIES
                    IMPORTED_LOCATION "${DOXYPRESS_EXECUTABLE}"
                    )
        endif ()
    endif ()
endmacro()

macro(_Doxypress_find_dia)
    set(_x86 "(x86)")
    find_program(
            DOXYPRESS_DIA_EXECUTABLE
            NAMES dia
            PATHS
            "$ENV{ProgramFiles}/Dia"
            "$ENV{ProgramFiles${_x86}}/Dia"
            DOC "Diagram Editor tool for use with Doxypress"
    )
    mark_as_advanced(DOXYPRESS_DIA_EXECUTABLE)

    if (DOXYPRESS_DIA_EXECUTABLE)
        # The Doxyfile wants the path to the utility, not the entire path
        # including file name
        get_filename_component(DOXYPRESS_DIA_PATH
                "${DOXYPRESS_DIA_EXECUTABLE}"
                DIRECTORY)
        if (WIN32)
            file(TO_NATIVE_PATH "${DOXYPRESS_DIA_PATH}" DOXYPRESS_DIA_PATH)
        endif ()

        # Create an imported target for component
        if (NOT TARGET Doxypress::dia)
            add_executable(Doxypress::dia IMPORTED GLOBAL)
            set_target_properties(Doxypress::dia PROPERTIES
                    IMPORTED_LOCATION "${DOXYPRESS_DIA_EXECUTABLE}"
                    )
        endif ()
    endif ()

    unset(_x86)
endmacro()

macro(_Doxypress_find_dot)
    if (WIN32)
        set(_x86 "(x86)")
        file(
                GLOB _Doxypress_GRAPHVIZ_BIN_DIRS
                "$ENV{ProgramFiles}/Graphviz*/bin"
                "$ENV{ProgramFiles${_x86}}/Graphviz*/bin"
        )
        unset(_x86)
    else ()
        set(_Doxypress_GRAPHVIZ_BIN_DIRS "")
    endif ()

    find_program(
            DOXYPRESS_DOT_EXECUTABLE
            NAMES dot
            PATHS
            ${_Doxypress_GRAPHVIZ_BIN_DIRS}
            "$ENV{ProgramFiles}/ATT/Graphviz/bin"
            "C:/Program Files/ATT/Graphviz/bin"
            [HKEY_LOCAL_MACHINE\\SOFTWARE\\ATT\\Graphviz;InstallPath]/bin
            /Applications/Graphviz.app/Contents/MacOS
            /Applications/Utilities/Graphviz.app/Contents/MacOS
            /Applications/Doxygen.app/Contents/Resources
            /Applications/Doxygen.app/Contents/MacOS
            /Applications/Utilities/Doxypress.app/Contents/Resources
            /Applications/Utilities/Doxypress.app/Contents/MacOS
            DOC "Dot tool for use with Doxypress"
    )
    mark_as_advanced(DOXYPRESS_DOT_EXECUTABLE)

    if (DOXYPRESS_DOT_EXECUTABLE)
        # The Doxyfile wants the path to the utility, not the entire path
        # including file name
        get_filename_component(DOXYPRESS_DOT_PATH
                "${DOXYPRESS_DOT_EXECUTABLE}"
                DIRECTORY)
        if (WIN32)
            file(TO_NATIVE_PATH "${DOXYPRESS_DOT_PATH}" DOXYPRESS_DOT_PATH)
        endif ()

        # Create an imported target for component
        if (NOT TARGET Doxypress::dot)
            add_executable(Doxypress::dot IMPORTED GLOBAL)
            set_target_properties(Doxypress::dot PROPERTIES
                    IMPORTED_LOCATION "${DOXYPRESS_DOT_EXECUTABLE}"
                    )
        endif ()
    endif ()

    unset(_Doxypress_GRAPHVIZ_BIN_DIRS)
endmacro()

#
# Find Message Sequence Chart...
#
macro(_Doxypress_find_mscgen)
    set(_x86 "(x86)")
    find_program(
            DOXYPRESS_MSCGEN_EXECUTABLE
            NAMES mscgen
            PATHS
            "$ENV{ProgramFiles}/Mscgen"
            "$ENV{ProgramFiles${_x86}}/Mscgen"
            DOC "Message sequence chart tool for use with Doxypress"
    )
    mark_as_advanced(DOXYPRESS_MSCGEN_EXECUTABLE)

    if (DOXYPRESS_MSCGEN_EXECUTABLE)
        # The Doxyfile wants the path to the utility, not the entire path
        # including file name
        get_filename_component(DOXYPRESS_MSCGEN_PATH
                "${DOXYPRESS_MSCGEN_EXECUTABLE}"
                DIRECTORY)
        if (WIN32)
            file(TO_NATIVE_PATH "${DOXYPRESS_MSCGEN_PATH}" DOXYPRESS_MSCGEN_PATH)
        endif ()

        # Create an imported target for component
        if (NOT TARGET Doxypress::mscgen)
            add_executable(Doxypress::mscgen IMPORTED GLOBAL)
            set_target_properties(Doxypress::mscgen PROPERTIES
                    IMPORTED_LOCATION "${DOXYPRESS_MSCGEN_EXECUTABLE}"
                    )
        endif ()
    endif ()

    unset(_x86)
endmacro()

# Make sure `DoxyPress` is one of the components to find
if (NOT Doxypress_FIND_COMPONENTS)
    # Search at least for `DoxyPress` executable
    set(Doxypress_FIND_COMPONENTS doxypress)
    # Preserve backward compatibility:
    # search for `dot` also if `DOXYPRESS_SKIP_DOT` is not explicitly disable this.
    if (NOT DOXYPRESS_SKIP_DOT)
        list(APPEND Doxypress_FIND_COMPONENTS dot)
    endif ()
elseif (NOT doxypress IN_LIST Doxypress_FIND_COMPONENTS)
    list(INSERT Doxypress_FIND_COMPONENTS 0 doxypress)
endif ()

#
# Find all requested components of Doxygen...
#
foreach (_comp IN LISTS Doxypress_FIND_COMPONENTS)
    if (_comp STREQUAL "doxypress")
        _Doxypress_find_doxypress()
    elseif (_comp STREQUAL "dia")
        _Doxypress_find_dia()
    elseif (_comp STREQUAL "dot")
        _Doxypress_find_dot()
    elseif (_comp STREQUAL "mscgen")
        _Doxypress_find_mscgen()
    else ()
        message(WARNING "${_comp} is not a valid Doxypress component")
        set(Doxypress_${_comp}_FOUND FALSE)
        continue()
    endif ()

    if (TARGET Doxypress::${_comp})
        set(Doxypress_${_comp}_FOUND TRUE)
    else ()
        set(Doxypress_${_comp}_FOUND FALSE)
    endif ()
endforeach ()
unset(_comp)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
        DoxypressCMake
        REQUIRED_VARS DOXYPRESS_EXECUTABLE
        VERSION_VAR DOXYPRESS_VERSION
        HANDLE_COMPONENTS
)

# Maintain the _FOUND variables as "YES" or "NO" for backwards
# compatibility. This allows people to substitute them directly into
# project file with configure_file().
if (DOXYPRESS_FOUND)
    set(DOXYPRESS_FOUND "YES")
else ()
    set(DOXYPRESS_FOUND "NO")
endif ()

include(${doxypress_dir}/AddDocs.cmake)
