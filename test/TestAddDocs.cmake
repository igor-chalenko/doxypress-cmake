function(test_input_directories_full_3)
    set("output-latex.generate-latex" false)
    doxypress_add_docs(
            INPUT_TARGET main
            INPUT_DIRECTORIES dir1 dir2 GENERATE_LATEX)

    doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)
    JSON_get("doxypress.input.input-source" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
    TPA_clear_scope()
endfunction()

test_input_directories_full_3()