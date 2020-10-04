##############################################################################
# Copyright (c) 2020 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

##############################################################################
#.rst:
# Doxypress target creation functions
# -----------------------------------
# Blah
##############################################################################


##############################################################################
#.rst:
# .. cmake:command:: _doxypress_create_targets
#
# ..  code-block:: cmake
#
#    _doxypress_create_targets(<project file> <processed project file>)
#
# Creates a `doxypress` target and an `open generated docs` target for every
# output format that was requested.
#
# Parameters:
#
# * ``_project_file``  unprocessed project file name
# * ``_updated_project_file`` processed project file name
##############################################################################
function(_doxypress_create_targets _project_file _updated_project_file)
    _JSON_get(doxypress.general.output-dir _output_dir)
    if (NOT _output_dir)
        message(FATAL_ERROR "Output directory may not be empty.")
    endif ()

    # _input_target can be empty
    TPA_get(INPUT_TARGET _input_target)
    if (_input_target)
        set(_prefix ${_input_target})
    else ()
        set(_prefix ${PROJECT_NAME})
    endif ()

    set(_doxypress_target ${_prefix}.doxypress)
    if (NOT TARGET "${_doxypress_target}")
        _doxypress_add_doc_targets("${_doxypress_target}" "${_output_dir}")
        _doxypress_add_open_targets("${_doxypress_target}" "${_output_dir}")
    endif ()
endfunction()

function(_doxypress_add_doc_targets _doxypress_target_name _output_dir)
    # collect inputs for `DEPENDS` parameter
    _doxypress_find_inputs(_inputs)
    # collect outputs for the `OUTPUTS` parameter
    _doxypress_list_outputs("${_output_dir}" _outputs)

    add_custom_command(OUTPUT ${_outputs}
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${_output_dir}
            DEPENDS "${_project_file}" "${_inputs}" "${_updated_project_file}"
            COMMAND Doxypress::doxypress "${_updated_project_file}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating API documentation with Doxypress..."
            BYPRODUCTS ${_output_dir}
            VERBATIM)

    add_custom_target(${_doxypress_target_name}
            DEPENDS ${_outputs}
            COMMENT "Generating docs...")

    if (_generate_pdf)
        file(MAKE_DIRECTORY ${_output_dir}/pdf)
        add_custom_command(TARGET
                ${_doxypress_target_name}
                POST_BUILD
                COMMAND
                ${CMAKE_MAKE_PROGRAM} #> ${_output_directory}/latex.log 2>&1
                WORKING_DIRECTORY
                "${_output_dir}/latex"
                COMMENT "Generating PDF..."
                VERBATIM)
        add_custom_command(TARGET ${_doxypress_target_name} POST_BUILD
                COMMENT "Copying refman.pdf to its own directory..."
                COMMAND ${CMAKE_COMMAND} -E copy
                "${_output_dir}/latex/refman.pdf"
                "${_output_dir}/pdf/refman.pdf")
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_find_inputs(_out_var)
#
# Collects input file names based on value of input parameters that control
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
function(_doxypress_find_inputs _out_var)
    TPA_get(INPUTS _inputs)
    TPA_get(INPUT_TARGET _input_target)

    set(_all_inputs "")
    if (_inputs)
        foreach (_dir ${_inputs})
            if (IS_DIRECTORY ${_dir})
                file(GLOB_RECURSE _inputs ${_dir}/*)
                list(APPEND _all_inputs "${_inputs}")
            else()
                list(APPEND _all_inputs "${_dir}")
            endif()
        endforeach ()
    elseif (_input_target)
        get_target_property(public_header_dirs
                ${_input_target}
                INTERFACE_INCLUDE_DIRECTORIES)
        foreach (_dir ${public_header_dirs})
            file(GLOB_RECURSE _inputs ${_dir}/*)
            list(APPEND _all_inputs "${_inputs}")
        endforeach ()
    else ()
        # todo better message
        message(FATAL_ERROR [=[
Either INPUTS or INPUT_TARGET must be specified as input argument
for `doxypress_add_docs`]=])
    endif ()

    set(${_out_var} "${_all_inputs}" PARENT_SCOPE)
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
#   by the ``doxypress`` target
##############################################################################
function(_doxypress_add_open_targets _name_prefix _output_dir)
    _JSON_get(doxypress.output-html.generate-html _generate_html)
    _JSON_get(doxypress.output-latex.generate-latex _generate_latex)
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
                    "${_output_dir}/latex/refman.pdf")
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
# ..  code-block:: cmake
#
#   _doxypress_install_docs(<destination directory> <install component>)
#
# Sets up install commands for the generated documentation.
# * HTML files are installed under ``_destination``/``html``
# * LaTex files are installed under ``_destination``/``latex``
# * PDF file is installed under ``_destination``/``pdf``
#
# Parameters:
#
# - ``destination`` install directory
# - ``component`` the value of ``COMPONENT`` parameter in the `install` command
##############################################################################
function(_doxypress_install_docs _destination _component)
    _JSON_get(doxypress.general.output-dir _output_directory)
    _JSON_get(doxypress.output-html.generate-html _generate_html)
    _JSON_get(doxypress.output-latex.generate-latex _generate_latex)
    TPA_get(GENERATE_PDF _generate_pdf)

    if (_generate_html)
        list(APPEND _artifacts ${_output_directory}/html)
    endif ()
    if (_generate_latex)
        file(GLOB _tex_files "${_output_directory}/latex/*.tex")
        list(APPEND _artifacts ${_tex_files})
    endif ()
    if (_generate_pdf)
        list(APPEND _artifacts "${_output_directory}/pdf/refman.pdf")
    endif ()

    foreach (_artifact ${_artifacts})
        _doxypress_log(INFO "install ${_artifact} to ${_destination}...")
        if (IS_DIRECTORY ${_artifact})
            install(DIRECTORY ${_artifact}
                    DESTINATION ${_destination}
                    COMPONENT ${_component})
        else ()
            install(FILES ${_artifact}
                    DESTINATION ${_destination}
                    COMPONENT ${_component})
        endif ()
    endforeach ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_project_generated_name
#
# ..  code-block:: cmake
#
#   _doxypress_project_generated_name(<project file name> <output variable>)
#
# Returns an absolute name of the output project file. Changes the input
# file's path while leaving the file name unchanged.
#
# Parameters:
#
# - ``_project_file`` input project file
# - ``_out_var`` output project file
##############################################################################
function(_doxypress_project_generated_name _project_file _out_var)
    if (IS_ABSOLUTE "${_project_file}")
        get_filename_component(_name "${_project_file}" NAME)
        set(${_out_var} ${CMAKE_CURRENT_BINARY_DIR}/${_name} PARENT_SCOPE)
    else ()
        set(${_out_var} ${CMAKE_CURRENT_BINARY_DIR}/${_project_file}
                PARENT_SCOPE)
    endif ()
endfunction()

##############################################################################
#.rst:
# .. cmake:command:: _doxypress_list_outputs
#
# ..  code-block:: cmake
#
#   _doxypress_list_outputs(<output directory> <output variable>)
#
# Collects file names into a list that is used in the ``OUTPUTS`` parameter of
# the `doxypress` target. If HTML generation was requested, ``index.html``
# is added to the list. If LaTex generation was requested, ''refman.tex` is
# added. If PDF was requested, ``refman.pdf`` is added.
##############################################################################
function(_doxypress_list_outputs _output_directory _out_var)
    # can't override these because they are in input parameters
    _JSON_get(doxypress.output-html.generate-html _html)
    _JSON_get(doxypress.output-latex.generate-latex _latex)
    TPA_get(GENERATE_PDF _pdf)

    if (_html)
        set(_html_index_file ${_output_directory}/html/index.html)
        list(APPEND _outputs ${_html_index_file})
    endif ()
    if (_latex)
        set(_latex_index_file ${_output_directory}/latex/refman.tex)
        list(APPEND _outputs ${_latex_index_file})
    endif ()
    if (_pdf)
        set(_pdf_file ${_output_directory}/pdf/refman.pdf)
        list(APPEND _outputs ${_pdf_file})
    endif ()

    set(${_out_var} "${_outputs}" PARENT_SCOPE)
endfunction()
