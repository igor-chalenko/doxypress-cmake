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
    doxypress_params_parse(INPUT_DIRECTORIES dir1 dir2)
    doxypress_project_update()

    TPA_get("INPUT_DIRECTORIES" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
    TPA_clear_scope()
endfunction()

# there's no target with the name ${PROJECT_NAME}, so the input sources are
# empty.
function(test_input_directories_2)
    doxypress_params_init()
    doxypress_params_parse(PROJECT_FILE DoxypressTest1.json INPUT_DIRECTORIES x)
    doxypress_project_load(DoxypressTest1.json)
    doxypress_project_update()

    TPA_get("INPUT_DIRECTORIES" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include2;${CMAKE_CURRENT_SOURCE_DIR}/include3;${CMAKE_CURRENT_SOURCE_DIR}/x")
    TPA_clear_scope()
endfunction()

# includes are taken from the input target
function(test_input_directories_3)
    add_executable(main main.cc)
    set_target_properties(main PROPERTIES EXCLUDE_FROM_ALL 1)
    target_include_directories(main PUBLIC include4 include5)

    doxypress_params_init()
    doxypress_params_parse(INPUT_TARGET main)
    doxypress_project_update()

    TPA_get("INPUT_DIRECTORIES" _inputs)
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


test_input_flags_1()
test_input_flags_2()
test_input_directories_1()
test_input_directories_2()
test_input_directories_3()
set(DOXYPRESS_DEBUG ON)
test_output_directory()