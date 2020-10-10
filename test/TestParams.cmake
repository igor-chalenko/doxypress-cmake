function(test_input_flags_1)
    include(../cmake/FindDoxypressCMake.cmake)

    _doxypress_params_init()
    _doxypress_inputs_parse(GENERATE_XML GENERATE_LATEX GENERATE_HTML false)

    TPA_get(GENERATE_XML _xml)
    TPA_get(GENERATE_LATEX _latex)
    TPA_get(GENERATE_HTML _html)
    assert_same(${_xml} true)
    assert_same(${_latex} true)
    assert_same(${_html} false)

    TPA_clear_scope()
endfunction()

function(test_input_flags_2)
    include(../cmake/FindDoxypressCMake.cmake)

    _doxypress_params_init()
    _doxypress_inputs_parse(GENERATE_LATEX)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)

    TPA_get(GENERATE_XML _xml)
    TPA_get(GENERATE_LATEX _latex)
    TPA_get(GENERATE_HTML _html)
    assert_same(${_xml} false)
    # assert_same(${_latex} true)
    assert_same(${_html} true)

    TPA_clear_scope()
endfunction()

# give input directories as input and read them back
function(test_input_directories_1)
    _doxypress_params_init()
    _doxypress_inputs_parse(INPUTS dir1 dir2)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)

    TPA_get("INPUTS" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
    TPA_clear_scope()
endfunction()

# there's no target with the name ${PROJECT_NAME}, so the input sources are
# empty.
function(test_input_directories_2)
    _doxypress_params_init()
    _doxypress_inputs_parse(PROJECT_FILE DoxypressTest1.json INPUTS x)
    _doxypress_project_update(DoxypressTest1.json _out)

    TPA_get("INPUTS" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include2;${CMAKE_CURRENT_SOURCE_DIR}/include3;${CMAKE_CURRENT_SOURCE_DIR}/x")
    TPA_clear_scope()
endfunction()

# includes are taken from the input target
function(test_input_directories_3)
    _doxypress_params_init()
    _doxypress_inputs_parse(INPUT_TARGET main)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)

    TPA_get(INPUTS _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include4;${CMAKE_CURRENT_SOURCE_DIR}/include5")
    TPA_clear_scope()
endfunction()

function(test_output_directory)
    _doxypress_params_init()
    _doxypress_inputs_parse(PROJECT_FILE DoxypressTest1.json
            OUTPUT_DIRECTORY "docs2")
    _doxypress_project_update(DoxypressTest1.json _out)

    TPA_get("OUTPUT_DIRECTORY" _output)
    assert_same("${_output}" "${CMAKE_CURRENT_BINARY_DIR}/docs2")
    TPA_clear_scope()
endfunction()

function(test_custom_project_file_1)
    _doxypress_params_init()
    _doxypress_inputs_parse(PROJECT_FILE DoxypressTest1.json)
    _doxypress_project_update(DoxypressTest1.json _out)

    TPA_get("PROJECT_FILE" _project_file)
    TPA_get("OUTPUT_DIRECTORY" _output)
    TPA_get("EXAMPLE_DIRECTORIES" _examples)

    assert_same("${_project_file}"
            "${CMAKE_CURRENT_SOURCE_DIR}/DoxypressTest1.json")
    assert_same("${_output}" "${CMAKE_CURRENT_BINARY_DIR}/docs1")
    assert_same("${_examples}"
            "${CMAKE_CURRENT_SOURCE_DIR}/examples1;${CMAKE_CURRENT_SOURCE_DIR}/examples2")
    TPA_clear_scope()
endfunction()

function(test_custom_project_file_2)
    _doxypress_params_init()
    _doxypress_inputs_parse(PROJECT_FILE DoxypressTest1.json
            EXAMPLE_DIRECTORIES x1 x2)
    _doxypress_project_update(DoxypressTest1.json _out)

    TPA_get("EXAMPLE_DIRECTORIES" _examples)
    assert_same("${_examples}"
            "${CMAKE_CURRENT_SOURCE_DIR}/examples1;${CMAKE_CURRENT_SOURCE_DIR}/examples2;${CMAKE_CURRENT_SOURCE_DIR}/x1;${CMAKE_CURRENT_SOURCE_DIR}/x2")
    TPA_clear_scope()
endfunction()

function(test_input_directories_full_1)
    _doxypress_override_add("messages.warnings" false)
    _doxypress_override_add("messages.quiet" false)
    _doxypress_override_add("configuration.toc-include-headers" 2)

    _doxypress_params_init()
    _doxypress_inputs_parse(INPUTS dir1 dir2)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)
    TPA_clear_scope()

    # todo fix out file name - dir is not cut
    _doxypress_project_load(${_out})
    _doxypress_get("${_DOXYPRESS_INPUT_SOURCE}" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")

    _doxypress_get("messages.warnings" _warnings)
    assert_same(${_warnings} false)
    _doxypress_get("messages.quiet" _quiet)
    assert_same(${_quiet} false)
    _doxypress_get("configuration.toc-include-headers" _headers)
    assert_same(${_headers} "2")
    TPA_clear_scope()
endfunction()

function(test_input_directories_full_2)
    _doxypress_override_add("messages.warnings" false)

    _doxypress_params_init()
    _doxypress_inputs_parse(INPUT_TARGET main)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)

    _doxypress_project_load(${_out})

    _doxypress_get("${_DOXYPRESS_INPUT_SOURCE}" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include4;${CMAKE_CURRENT_SOURCE_DIR}/include5")
    _doxypress_get("messages.warnings" _warnings)
    assert_same(${_warnings} false)
    TPA_clear_scope()
endfunction()

# Make sure LATEX module is imported when GENERATE_LATEX is true.
# Will only perform the tests if latex is installed.
function(test_latex_find_package)
    _doxypress_params_init()
    _doxypress_inputs_parse(GENERATE_LATEX)
    _doxypress_project_update(../cmake/DoxypressCMake.json _out)

    TPA_get(LATEX_FOUND _latex_found)
    if (_latex_found STREQUAL "")
        assert_same("LATEX_FOUND not set" "")
    endif()
    TPA_clear_scope()
endfunction()

test_input_flags_1()
test_input_flags_2()
test_input_directories_1()
test_input_directories_2()
test_input_directories_3()
test_output_directory()
test_custom_project_file_1()
test_custom_project_file_2()
#set(DOXYPRESS_LOG_LEVEL DEBUG)
test_input_directories_full_1()
test_input_directories_full_2()
test_latex_find_package()
