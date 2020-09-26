#.rst:
# BasicPlugin
# -----------
#
# .. code-block:: cmake
#
#   include(BasicPlugin)
#
# Supplies a function for building ``cetlib`` compatible plugin libraries. Note that
# this provides a slightly different API from the ``cetbuildtools`` version to
# decouple the build/install steps and to remove UPS specifics.
#
# The following function for building plugin libraries is defined
#
# .. cmake:command:: basic_plugin
#
#  ..  code-block:: cmake
#
#    basic_plugin(<name>
#                 <plugintype>
#                 [[NOP] <libraries>]
#                 [USE_BOOST_UNIT]
#                 [ALLOW_UNDERSCORES]
#                 [BASENAME_ONLY]
#                 [USE_PRODUCT_NAME]
#                 [SOURCE <sources>])
#
# The plugin library's name is constructed from the specified ``<name>``,
# ``<plugintype>`` (eg service, module, source), and (unless
# BASENAME_ONLY is specified) the package subdirectory path (replacing
# "/" with "_"). The plugin type is expected to be ``service``, ``source``, or ``module``,
# but this is not enforced.
#
# Options:
#
# ALLOW_UNDERSCORES
#   Allow underscores in subdirectory names. Discouraged, as it creates
#   a possible ambiguity in the encoded plugin library name
#   (e.g. ``foo_bar/baz`` is indistinguishable from ``foo/bar/baz``).
#
# BASENAME_ONLY
#   Omit the subdirectory path from the library name. Discouraged, as
#   it creates an ambiguity between modules with the same source
#   filename in different packages or different subdirectories within
#   the same package. The latter case is not possible however, because
#   CMake will throw an error because the two CMake targets will have
#   the same name and that is not permitted. Mutually exclusive with
#   ``USE_PRODUCT_NAME``.
#
# NOP
#   Dummy option for the purpose of separating (say) multi-option
#   arguments from non-option arguments.
#
# SOURCE
#   If specified, the provided sources will be used to create the
#   library. Otherwise, the generated name ``<name>_<plugin_type>.cc`` will
#   be used and this will be expected to be found in the current CMake
#   source directory (``CMAKE_CURRENT_SOURCE_DIR``).
#
# USE_BOOST_UNIT
#   Build the plugin to allow its use in Boost.Unit tests
#
# USE_PRODUCT_NAME
#    Prepend the product name (value of ``PROJECT_NAME`` in non-UPS) to the
#    plugin library name. Mutually exclusive with ``BASENAME_ONLY``.
#
# .. todo::
#
#   It is likely that this module should be promoted to cetlib because
#   the major functionality of the module is to enforce the cetlib plugin
#   naming convention. If this convention changes, then it is most clearly communicated
#   via changes to the cetlib API. Otherwise, all this module does is to use
#   add_library/target_link_libraries that any user would be comfortable with.
#

include(CMakeParseArguments)
include(CetCurrentSubdir)
include(CetCMakeUtilities)


# Basic plugin libraries.
function(basic_plugin name type)
    cmake_parse_arguments(BP
            "USE_BOOST_UNIT;ALLOW_UNDERSCORES;BASENAME_ONLY;USE_PRODUCT_NAME;NOP;NO_INSTALL"
            ""
            "SOURCE"
            ${ARGN})
    if(BP_BASENAME_ONLY AND BP_USE_PRODUCT_NAME)
        message(FATAL_ERROR "BASENAME_ONLY AND USE_PRODUCT_NAME are mutually exclusive")
    endif()
    if(BP_NO_INSTALL)
        message(WARNING "basic_plugin no longer accepts the NO_INSTALL option")
    endif()

    if(BP_BASENAME_ONLY)
        set(plugin_name "${name}_${type}")
    else()
        # base name on current subdirectory
        _cet_current_subdir(CURRENT_SUBDIR2)
        # remove leading /
        string(REGEX REPLACE "^/(.*)" "\\1" CURRENT_SUBDIR "${CURRENT_SUBDIR2}")
        if(NOT BP_ALLOW_UNDERSCORES)
            string(REGEX MATCH [_] has_underscore "${CURRENT_SUBDIR}")
            if(has_underscore)
                message(FATAL_ERROR  "found underscore in plugin subdirectory: ${CURRENT_SUBDIR}" )
            endif()

            string(REGEX MATCH [_] has_underscore "${name}")
            if(has_underscore)
                message(FATAL_ERROR  "found underscore in plugin name: ${name}" )
            endif()
        endif()

        string(REGEX REPLACE "/" "_" plugname "${CURRENT_SUBDIR}")
        if(BP_USE_PRODUCT_NAME)
            set(plugname ${PROJECT_NAME}_${plugname})
        endif()
        set(plugin_name "${plugname}_${name}_${type}")
    endif()

    if(NOT BP_SOURCE)
        set(BP_SOURCE "${name}_${type}.cc")
    endif()

    add_library(${plugin_name} SHARED ${BP_SOURCE})

    # check the library list and substitute if appropriate
    # Probably not needed as would expect user to supply appropriate list
    # without any transformation
    set(basic_plugin_liblist "")
    foreach(lib ${BP_UNPARSED_ARGUMENTS})
        string(REGEX MATCH [/] has_path "${lib}")
        if(has_path)
            list(APPEND basic_plugin_liblist ${lib})
        else()
            string(TOUPPER  ${lib} ${lib}_UC )
            if( ${${lib}_UC} )
                list(APPEND basic_plugin_liblist ${${${lib}_UC}})
            else()
                list(APPEND basic_plugin_liblist ${lib})
            endif()
        endif()
    endforeach()

    if(BP_USE_BOOST_UNIT)
        set_boost_unit_properties(${plugin_name})
    endif()

    set_tbb_offload_properties(${plugin_name})

    list(LENGTH basic_plugin_liblist liblist_length)
    if(liblist_length GREATER 0)
        target_link_libraries(${plugin_name} ${basic_plugin_liblist})
    endif()
endfunction()
