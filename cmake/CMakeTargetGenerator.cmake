##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
#
# .. _cmake-target-generator-reference-label:
#
# CMake target generator
# ----------------------
#
# This module implements creation of the following targets:
#
# * ``${TARGET_NAME}`` to run `DoxyPress`;
# * ``${TARGET_NAME}.open_html``:
#
#   .. code-block:: bash
#
#      ${DOXYPRESS_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/html/index.html
#
#   This target is created unless HTML generation was disabled.
#
#   * ``${TARGET_NAME}.latex``:
#
#   .. code-block:: bash
#
#      ${DOXYPRESS_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/latex/refman.tex
#
#   This target is created if LaTex generation was enabled.
#
#   * ``${TARGET_NAME}.pdf``:
#
#   .. code-block:: bash
#
#      ${DOXYPRESS_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/pdf/refman.pdf
#
#   This target is created if PDF generation was enabled.
#
# In addition to the above, ``doxypress-cmake`` uses
# :cmake:command:`_doxypress_install_docs` to add documentation files to the
# ``install`` target.
#
# See also:
#
# * :cmake:variable:`DOXYPRESS_LAUNCHER_COMMAND`
##############################################################################

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_add_targets
#
# ..  code-block:: cmake
#
#    _doxypress_add_targets(<project file> <processed project file>)
#
# Creates a `DoxyPress` target and an `open generated docs` target for every
# output format that was requested.
#
# Parameters:
#
# * ``_project_file``  unprocessed project file name
# * ``_updated_project_file`` processed project file name
##############################################################################
function(_doxypress_add_targets _project_file _updated_project_file)
    _doxypress_assert_not_empty("${_project_file}")
    _doxypress_assert_not_empty("${_updated_project_file}")

    TPA_get(TARGET_NAME _target_name)
    if (NOT TARGET "${_target_name}")
        _doxypress_add_target("${_project_file}"
                "${_updated_project_file}"
                "${_target_name}")
        _doxypress_add_pdf_commands("${_target_name}")
        if (DOXYPRESS_ADD_OPEN_TARGETS)
            _doxypress_add_open_targets("${_target_name}" )
        endif ()
    else()
        _doxypress_log(WARN "The target ${_target_name} already exists.")
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_add_target
#
# ..  code-block:: cmake
#
#    _doxypress_add_target(<project file name>
#                          <processed project file name>
#                          <target name>)
#
# Creates a `DoxyPress` target ``_target_name`` and an `open generated docs`
# target for every output format that was requested.
#
# Parameters:
#
# * ``_project_file``  unprocessed project file name
# * ``_updated_project_file`` processed project file name
# * ``_target_name`` the name of the target to create
##############################################################################
function(_doxypress_add_target _project_file _updated_project_file _target_name)
    _doxypress_get(general.output-dir _output_dir)
    # collect inputs for `DEPENDS` parameter
    _doxypress_list_inputs(_inputs)
    _doxypress_assert_not_empty("${_inputs}")
    # collect outputs for the `OUTPUTS` parameter
    _doxypress_list_outputs("${_output_dir}" _files FILES)

    add_custom_command(OUTPUT ${_files}
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${_output_dir}
            DEPENDS "${_project_file}" "${_inputs}" "${_updated_project_file}"
            COMMAND Doxypress::doxypress "${_updated_project_file}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating API documentation with Doxypress..."
            BYPRODUCTS ${_output_dir}
            VERBATIM)

    add_custom_target(${_target_name}
            DEPENDS ${_files}
            COMMENT "Generating docs...")
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_add_pdf_commands
#
# ..  code-block:: cmake
#
#    _doxypress_add_pdf_commands(<target name>)
#
# Adds PDF generation commands to a previously created `DoxyPress` target
# ``_target_name``.
#
# Parameters:
#
# * ``_target_name`` the name of the target to add commands to
##############################################################################
function(_doxypress_add_pdf_commands _target_name)
    TPA_get(GENERATE_PDF _pdf)
    _doxypress_get(general.output-dir _output_dir)

    if (_pdf)
        file(MAKE_DIRECTORY ${_output_dir}/pdf)
        add_custom_command(TARGET
                ${_target_name}
                POST_BUILD
                COMMAND
                ${CMAKE_MAKE_PROGRAM} #> ${_output_directory}/latex.log 2>&1
                WORKING_DIRECTORY
                "${_output_dir}/latex"
                COMMENT "Generating PDF..."
                VERBATIM)
        add_custom_command(TARGET ${_target_name} POST_BUILD
                COMMENT "Copying refman.pdf to its own directory..."
                COMMAND ${CMAKE_COMMAND} -E copy
                "${_output_dir}/latex/refman.pdf"
                "${_output_dir}/pdf/refman.pdf")
        add_custom_command(TARGET ${_target_name} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E rm "${_output_dir}/latex/refman.pdf")
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_add_open_targets
#
# ..  code-block:: cmake
#
#    _doxypress_add_open_targets(<name prefix> <output directory>)
#
# Parameters:
#
# * ``_name_prefix`` a string prepended to the names of the targets being
#   created
# * ``_output_dir`` a directory where documentation files will be generated
#   by the ``DoxyPress`` target
##############################################################################
function(_doxypress_add_open_targets _name_prefix)
    _doxypress_get(general.output-dir _output_dir)
    _doxypress_get(output-html.generate-html _generate_html)
    _doxypress_get(output-latex.generate-latex _generate_latex)
    TPA_get(GENERATE_PDF _generate_pdf)

    if (DOXYPRESS_LAUNCHER_COMMAND)
        if (_generate_html AND NOT TARGET ${_name_prefix}.open_html)
            # Create a target to open the generated HTML file.
            _doxypress_add_open_target(
                    ${_name_prefix}.open_html
                    ${_name_prefix}
                    "${_output_dir}/html/index.html")
        endif ()
        if (_generate_latex AND NOT TARGET ${_name_prefix}.open_latex)
            _doxypress_add_open_target(
                    ${_name_prefix}.open_latex
                    ${_name_prefix}
                    "${_output_dir}/latex/refman.tex")
        endif ()
        if (_generate_pdf AND NOT TARGET ${_name_prefix}.open_pdf)
            _doxypress_add_open_target(
                    ${_name_prefix}.open_pdf
                    ${_name_prefix}
                    "${_output_dir}/pdf/refman.pdf")
        endif ()
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_add_open_target
#
# ..  code-block:: cmake
#
#   _doxypress_add_open_target(<target name> <parent target name> <file name>)
#
# Creates a target that opens a given file for viewing. Synonymous
# to `start file` on Windows or `xdg-open file` on Gnome desktops.
#
# Parameters:
#
# * ``_target_name`` a name of the newly created target that should open 
#   the given file
# * ``_parent_target_name`` a name of the target that generates documentation;
#   serves as a dependency for the target ``_target_name``
# * ``_file`` a file to open, such as `index.html`
##############################################################################
function(_doxypress_add_open_target _target_name _parent_target_name _file)
    _doxypress_log(INFO "Adding launch target ${_target_name} for ${_file}...")
    add_custom_target(${_target_name}
            COMMAND ${DOXYPRESS_LAUNCHER_COMMAND} "${_file}"
            COMMENT "Opening ${_file}..."
            VERBATIM)
    set_target_properties(${_target_name}
            PROPERTIES
            EXCLUDE_FROM_DEFAULT_BUILD TRUE
            EXCLUDE_FROM_ALL TRUE)
    add_dependencies(${_target_name} ${_parent_target_name})
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_install_docs
#
# Sets up install commands for the generated documentation.
#
# * HTML files are installed under ``_destination``/``html``
# * LaTex files are installed under ``_destination``/``latex``
# * PDF file is installed under ``_destination``/``pdf``
#
# These
##############################################################################
function(_doxypress_install_docs)
    _doxypress_get(general.output-dir _output_dir)
    TPA_get(INSTALL_COMPONENT _component)

    if (NOT DEFINED CMAKE_INSTALL_DOCDIR)
        set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_PREFIX}")
        include(GNUInstallDirs)
    endif ()
    set(_destination ${CMAKE_INSTALL_DOCDIR})

    _doxypress_list_outputs("${_output_dir}" _files DIRECTORIES)

    foreach (_artifact ${_files})
        _doxypress_log(INFO "install ${_artifact} to ${_destination}...")
        install(DIRECTORY ${_artifact}
                DESTINATION ${_destination}
                COMPONENT ${_component}
        )
    endforeach ()
endfunction()


##############################################################################
#.rst:
# .. cmake:command:: _doxypress_list_outputs
#
# ..  code-block:: cmake
#
#   _doxypress_list_outputs(<mode> <output variable>)
#
# Collects configured `DoxyPress` outputs. Two modes of operation are
# supported, controlled by the ``mode`` parameter. The following ``mode`` values
# are accepted:
#
# * ``FILES``
#   In this mode, ``index.html``, ``index.xml``, ``refman.tex``, and
#   ``refman.pdf`` are added to the result, depending on whether
#   the corresponding format generation was requested.
# * ``DIRECTORIES``
#   In this mode, ``html``, ``xml``, ``latex``, and ``pdf`` directories are
#   added to the result (their absolute paths, to be precise).
##############################################################################
function(_doxypress_list_outputs _option _out_var)
    # can't override these because they are in input parameters
    _doxypress_get(output-html.generate-html _html)
    _doxypress_get(output-xml.generate-xml _xml)
    _doxypress_get(output-latex.generate-latex _latex)
    _doxypress_get(general.output-dir _output_dir)
    TPA_get(GENERATE_PDF _pdf)

    set(_out "")
    if (_option STREQUAL FILES)
        if (_html)
            set(_html_index_file "${_output_dir}/html/index.html")
            list(APPEND _out "${_html_index_file}")
        endif ()
        if (_xml)
            set(_xml_index_file "${_output_dir}/xml/index.xml")
            list(APPEND _out "${_xml_index_file}")
        endif ()
        if (_latex)
            set(_latex_index_file "${_output_dir}/latex/refman.tex")
            list(APPEND _out "${_latex_index_file}")
        endif ()
        if (_pdf AND)
            set(_pdf_file "${_output_dir}/pdf/refman.pdf")
            list(APPEND _out "${_pdf_file}")
        endif ()
    else ()
        list(APPEND _out "${_output_dir}/latex")
        list(APPEND _out "${_output_dir}/xml")
        list(APPEND _out "${_output_dir}/html")
        list(APPEND _out "${_output_dir}/pdf")
    endif ()

    set(${_out_var} "${_out}" PARENT_SCOPE)
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_list_inputs(_out_var)
#
# Collects input file names based on the value of input parameters that control
# input sources:
# * If ``INPUTS`` is not empty, collects all files in the paths given by
# ``INPUTS``. Files are added to the resulting list directly, and directories
# are globbed. Puts the resulting list into ``_out_var``.
# * If ``INPUT_TARGET`` is not empty, takes include directories from
# the corresponding target. Every directory is then globbed to get the files.
# * If none of the above holds, an error is raised.
#
# Parameters:
#
# * ``_out_var`` the list of files in input sources
##############################################################################
function(_doxypress_list_inputs _out_var)
    TPA_get(INPUTS _inputs)
    TPA_get(INPUT_TARGET _input_target)

    set(_all_inputs "")
    if (_inputs)
        foreach (_dir ${_inputs})
            if (IS_DIRECTORY ${_dir})
                file(GLOB_RECURSE _inputs ${_dir}/*)
                list(APPEND _all_inputs "${_inputs}")
            else ()
                list(APPEND _all_inputs "${_dir}")
            endif ()
        endforeach ()
    elseif (_input_target)
        get_target_property(_include_directories
                ${_input_target}
                INTERFACE_INCLUDE_DIRECTORIES)
        foreach (_dir ${_include_directories})
            string(FIND ${_dir} "$<BUILD_INTERFACE:" _ind)
            string(FIND ${_dir} "$<INSTALL_INTERFACE:" _ind2)
            if (_ind2 EQUAL -1)
                if (_ind GREATER -1)
                    string(LENGTH "${_dir}" _length)
                    math(EXPR _length "${_length} - 19")
                    string(SUBSTRING "${_dir}" 18 ${_length} _new_include)
                    file(GLOB_RECURSE _inputs ${_new_include}/*)
                else()
                    file(GLOB_RECURSE _inputs "${_dir}/*")
                    list(APPEND _all_inputs "${_inputs}")
                endif()
            endif()
        endforeach ()
    else ()
        message(FATAL_ERROR [=[
Either INPUTS or INPUT_TARGET must be specified as input argument
for `doxypress_add_docs`:
1) INPUT_TARGET couldn't be defaulted to ${PROJECT_NAME};
2) Input project file didn't specify any inputs either.]=])
    endif ()

    set(${_out_var} "${_all_inputs}" PARENT_SCOPE)
endfunction()
