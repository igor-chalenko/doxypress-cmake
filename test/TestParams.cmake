function(test_input_flags_1)
    include(../cmake/FindDoxypressCMake.cmake)

    doxypress_params_init()
    doxypress_params_parse(GENERATE_XML GENERATE_LATEX GENERATE_HTML false)

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

    doxypress_params_init()
    doxypress_params_parse(GENERATE_LATEX)
    doxypress_project_update()

    TPA_get(GENERATE_XML _xml)
    TPA_get(GENERATE_LATEX _latex)
    TPA_get(GENERATE_HTML _html)
    assert_same(${_xml} false)
    assert_same(${_latex} true)
    assert_same(${_html} true)

    TPA_clear_scope()
endfunction()

# give input directories as input and read them back
function(test_input_directories_1)
    doxypress_params_init()
    doxypress_params_parse(INPUTS dir1 dir2)
    doxypress_project_update()

    TPA_get("INPUTS" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
    TPA_clear_scope()
endfunction()

# there's no target with the name ${PROJECT_NAME}, so the input sources are
# empty.
function(test_input_directories_2)
    doxypress_params_init()
    doxypress_params_parse(PROJECT_FILE DoxypressTest1.json INPUTS x)
    doxypress_project_load(DoxypressTest1.json)
    doxypress_project_update()

    TPA_get("INPUTS" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include2;${CMAKE_CURRENT_SOURCE_DIR}/include3;${CMAKE_CURRENT_SOURCE_DIR}/x")
    TPA_clear_scope()
endfunction()

# includes are taken from the input target
function(test_input_directories_3)
    doxypress_params_init()
    doxypress_params_parse(INPUT_TARGET main)
    doxypress_project_update()

    TPA_get(INPUTS _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include4;${CMAKE_CURRENT_SOURCE_DIR}/include5")
    TPA_clear_scope()
endfunction()

function(test_output_directory)
    doxypress_params_init()
    doxypress_params_parse(PROJECT_FILE DoxypressTest1.json
            OUTPUT_DIRECTORY "docs2")
    doxypress_project_load(DoxypressTest1.json)
    doxypress_project_update()

    TPA_get("OUTPUT_DIRECTORY" _output)
    assert_same("${_output}" "${CMAKE_CURRENT_BINARY_DIR}/docs2")
    TPA_clear_scope()
endfunction()

function(test_custom_project_file_1)
    doxypress_params_init()
    doxypress_params_parse(PROJECT_FILE DoxypressTest1.json)
    doxypress_project_load(DoxypressTest1.json)
    doxypress_project_update()

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
    doxypress_params_init()
    doxypress_params_parse(PROJECT_FILE DoxypressTest1.json
            EXAMPLE_DIRECTORIES x1 x2)
    doxypress_project_load(DoxypressTest1.json)
    doxypress_project_update()

    TPA_get("EXAMPLE_DIRECTORIES" _examples)
    assert_same("${_examples}"
            "${CMAKE_CURRENT_SOURCE_DIR}/examples1;${CMAKE_CURRENT_SOURCE_DIR}/examples2;${CMAKE_CURRENT_SOURCE_DIR}/x1;${CMAKE_CURRENT_SOURCE_DIR}/x2")
    TPA_clear_scope()
endfunction()

function(test_input_directories_full_1)
    set("messages.warnings" false)
    set("messages.quiet" false)

    doxypress_params_init()
    doxypress_params_parse(INPUTS dir1 dir2)
    doxypress_project_load(../cmake/DoxypressCMake.json)
    doxypress_project_update()
    doxypress_project_save(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)

    doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)
    JSON_get("doxypress.input.input-source" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")

    JSON_get("doxypress.messages.warnings" _warnings)
    assert_same(${_warnings} false)
    JSON_get("doxypress.messages.quiet" _quiet)
    assert_same(${_quiet} false)
    TPA_clear_scope()
endfunction()

function(test_input_directories_full_2)
    set("messages.warnings" false)

    doxypress_params_init()
    doxypress_params_parse(INPUT_TARGET main)
    doxypress_project_load(../cmake/DoxypressCMake.json)
    doxypress_project_update()
    doxypress_project_save(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)

    doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)

    JSON_get("doxypress.input.input-source" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include4;${CMAKE_CURRENT_SOURCE_DIR}/include5")
    JSON_get("doxypress.messages.warnings" _warnings)
    assert_same(${_warnings} false)
    TPA_clear_scope()
endfunction()

# Make sure LATEX module is imported when GENERATE_LATEX is true.
# Will only perform the tests if latex is installed.
function(test_latex_find_package)
    doxypress_params_init()
    doxypress_params_parse(GENERATE_LATEX)
    doxypress_project_update()

    if (NOT DEFINED LATEX_FOUND)
        assert_same("LATEX_FOUND not set" "")
    endif()
    TPA_clear_scope()
endfunction()

message(STATUS "Running tests...")
test_input_flags_1()
test_input_flags_2()
test_input_directories_1()
test_input_directories_2()
test_input_directories_3()
test_output_directory()
test_custom_project_file_1()
test_custom_project_file_2()
# set(DOXYPRESS_DEBUG ON)
test_input_directories_full_1()
test_input_directories_full_2()
test_latex_find_package()
