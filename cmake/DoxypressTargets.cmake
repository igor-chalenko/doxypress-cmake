function(doxypress_create_targets _project_file)
    set(_outputs "")
    # todo constant
    # JSON_get(doxypress.output-html.html-file-extension _html_extension)
    JSON_get(doxypress.general.output-dir _output_directory)
    JSON_get(doxypress.output-html.generate-html _generate_html)
    JSON_get(doxypress.output-latex.generate-latex _generate_latex)
    TPA_get(GENERATE_PDF _generate_pdf)

    if (_generate_html)
        set(_html_index_file ${_output_directory}/html/index.html)
        list(APPEND _outputs ${_html_index_file})
    endif()
    if (_generate_latex)
        set(_latex_index_file ${_output_directory}/latex/refman.tex)
        list(APPEND _outputs ${_latex_index_file})
    endif()
    if (_generate_pdf)
        set(_pdf_file ${_output_directory}/pdf/refman.pdf)
        list(APPEND _outputs ${_pdf_file})
    endif()

    TPA_get(INPUT_DIRECTORIES _input_directories)
    TPA_get(INPUT_TARGET _input_target)

    doxypress_find_inputs(_public_headers
            DIRECTORIES "${_input_directories}"
            TARGET "${_input_target}")

    doxypress_file_name("${_project_file}" _relative_file_name)

    add_custom_command(OUTPUT ${_outputs}
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${_output_directory}
            DEPENDS ${_public_headers} ${_project_file}
            COMMAND Doxypress::doxypress
            "${CMAKE_CURRENT_BINARY_DIR}/${_relative_file_name}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            MAIN_DEPENDENCY "${CMAKE_CURRENT_BINARY_DIR}/${_relative_file_name}"
            COMMENT "Generating API documentation with Doxypress..."
            BYPRODUCTS "${_output_directory}"
            VERBATIM)

    if (NOT TARGET ${_input_target}.doxypress)
        add_custom_target(${_input_target}.doxypress DEPENDS ${_outputs})
    endif()

    if (_generate_pdf)
        file(MAKE_DIRECTORY ${_output_directory}/pdf)
        add_custom_command(TARGET
                ${_input_target}.doxypress
                POST_BUILD
                COMMAND
                ${CMAKE_MAKE_PROGRAM} #> ${_output_directory}/latex.log 2>&1
                WORKING_DIRECTORY
                "${_output_directory}/latex"
                COMMENT
                "Generating PDF using PDFLaTeX..."
                VERBATIM)
        add_custom_command(TARGET ${_input_target}.doxypress POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                "${_output_directory}/latex/refman.pdf"
                "${_output_directory}/pdf/refman.pdf")
    endif ()

    doxypress_create_open_targets(${_input_target}.doxypress)
endfunction()

# -----------------------------------------------------------------------------
# @brief Determines a set of input files for processing. Puts the resulting list
# into `out_var`.
#
# @param[in] DIRECTORIES       list of input directories to scan
# @param[in] TARGET            input target name to read
# @param[out] out_var          output variable
# -----------------------------------------------------------------------------
function(doxypress_find_inputs _out_var)
    set(options "")
    set(oneValueArgs DIRECTORIES TARGET)
    set(multiValueArgs "")

    cmake_parse_arguments(INPUT
            "${options}"
            "${oneValueArgs}"
            "${multiValueArgs}"
            ${ARGN})

    set(all_public_headers "")
    if (DEFINED INPUT_DIRECTORIES)
        foreach (dir ${INPUT_DIRECTORIES})
            file(GLOB_RECURSE public_headers ${dir}/*)
            list(APPEND all_public_headers "${public_headers}")
        endforeach ()
    elseif (DEFINED INPUT_TARGET)
        get_target_property(public_header_dirs
                ${INPUT_TARGET}
                INTERFACE_INCLUDE_DIRECTORIES)
        foreach (dir ${public_header_dirs})
            file(GLOB_RECURSE public_headers ${dir}/*)
            list(APPEND all_public_headers "${public_headers}")
        endforeach ()
    else ()
        # todo better message
        message(FATAL_ERROR [=[
Either INPUT_DIRECTORIES or INPUT_TARGET must be specified as input argument
for `doxypress_add_docs`]=])
    endif ()

    set(${_out_var} "${all_public_headers}" PARENT_SCOPE)
endfunction()

function(doxypress_create_open_targets _name_prefix)
    JSON_get(doxypress.output-html.generate-html _generate_html)
    JSON_get(doxypress.output-latex.generate-latex _generate_latex)
    TPA_get(GENERATE_PDF _generate_pdf)
    JSON_get(doxypress.general.output-dir _output_directory)

    message(STATUS "_output_directory = ${_output_directory}")
    # JSON_get(doxypress.output-html.html-file-extension _html_extension)

    if (DOXYPRESS_LAUNCHER_COMMAND)
        if (_generate_html AND NOT TARGET ${_name_prefix}.open_html)
            # Create a target to open the generated HTML file.
            doxypress_create_open_target(
                    ${_name_prefix}.open_html
                    ${_name_prefix}
                    "${_output_directory}/html/index.html")
        endif ()
        if (_generate_latex AND NOT TARGET ${_name_prefix}.open_latex)
            doxypress_create_open_target(
                    ${_name_prefix}.open_latex
                    ${_name_prefix}
                    "${_output_directory}/latex/refman.tex")
        endif ()
        if (_generate_pdf AND NOT TARGET ${_name_prefix}.open_pdf)
            doxypress_create_open_target(
                    ${_name_prefix}.open_pdf
                    ${_name_prefix}
                    "${_output_directory}/latex/refman.pdf")
        endif ()
    endif ()
endfunction()

# -----------------------------------------------------------------------------
# @brief Creates a build target that opens a given file for viewing. Synonymous
# to `start file` on Windows or `xdg-open file` on Gnome desktops.
#
# @param[in] target_name           a name of the newly created target that
#                                  should open the given file
# @param[in] parent_target_name    a name of the target that generates
#                                  documentation; serves as a dependency for
#                                  the target `target_name`, created by this
#                                  function.
# @param[in] file                  a file to open, such as `index.html`
function(doxypress_create_open_target _target_name _parent_target_name _file)
    doxypress_log(INFO "Adding launch target ${_target_name} for ${_file}...")
    add_custom_target(${_target_name}
            COMMAND ${DOXYPRESS_LAUNCHER_COMMAND} "${_file}"
            VERBATIM)
    set_target_properties(${_target_name}
            PROPERTIES
            EXCLUDE_FROM_DEFAULT_BUILD TRUE
            EXCLUDE_FROM_ALL TRUE)
    add_dependencies(${_target_name} ${_parent_target_name})
endfunction()

# -----------------------------------------------------------------------------
# @brief Generates install commands for the given artifacts:
# -# a directory will be installed as a sub-directory of `destination`
# -# a file's path relative to `output_dir` will be appended to `destination`
#
# @param[in] artifacts             a list of files/directories to install
# @param[in] output_dir            relocation root directory
# @param[in] destination           install directory
# @param[in] component             install component name
# -----------------------------------------------------------------------------
function(doxypress_install_docs _destination _component)
    JSON_get(doxypress.general.output-dir _output_directory)
    JSON_get(doxypress.output-html.generate-html _generate_html)
    JSON_get(doxypress.output-latex.generate-latex _generate_latex)
    TPA_get(GENERATE_PDF _generate_pdf)

    if (_generate_html)
        list(APPEND _artifacts ${_output_directory}/html)
    endif ()
    if (_generate_latex)
        file(GLOB _tex_files "${_output_directory}/latex/*.tex")
        list(APPEND _artifacts ${_tex_files})
        # doxypress_log(INFO "LaTex docs will be installed...")
    endif ()
    if (_generate_pdf)
        list(APPEND _artifacts "${_output_directory}/pdf/refman.pdf")
    endif ()

    foreach (_artifact ${_artifacts})
        doxypress_log(INFO "install ${_artifact} to ${_destination}...")
        if (IS_DIRECTORY ${_artifact})
            install(DIRECTORY ${_artifact}
                    DESTINATION ${_destination}
                    COMPONENT ${_component})
        else()
            install(FILES ${_artifact}
                    DESTINATION ${_destination}
                    COMPONENT ${_component})
        endif()
    endforeach ()
endfunction()

function(doxypress_file_name _full_name _out_var)
    if (IS_ABSOLUTE "${_full_name}")
        get_filename_component(_name "${_full_name}" NAME)
        set(${_out_var} ${_name} PARENT_SCOPE)
    else()
        set(${_out_var} ${_full_name} PARENT_SCOPE)
    endif ()
endfunction()
