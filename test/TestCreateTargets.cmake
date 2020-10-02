function(test_create_targets)
    JSON_set(doxypress.general.output-dir "${CMAKE_CURRENT_BINARY_DIR}")
    JSON_set(doxypress.output-html.generate-html true)
    JSON_set(doxypress.output-latex.generate-latex true)
    TPA_set(GENERATE_PDF true)

    add_custom_target(_test COMMAND "${CMAKE_COMMAND} --version")
    TPA_set(INPUT_TARGET _test)
    configure_file(DoxypressTest1.json
            ${CMAKE_CURRENT_BINARY_DIR}/DoxypressTest1.json @ONLY)
    doxypress_create_targets(${PROJECT_SOURCE_DIR}/DoxypressTest1.json
            ${CMAKE_CURRENT_BINARY_DIR}/DoxypressTest1.json)

    if (NOT TARGET _test.doxypress)
        assert_same("doxypress target `_test.doxypress` was not created")
    endif()
    if (NOT TARGET _test.doxypress.open_html)
        assert_same("The target `_test.doxypress.open_html` was not created")
    endif()
    if (NOT TARGET _test.doxypress.open_latex)
        assert_same("The target `_test.doxypress.open_latex` was not created")
    endif()
    if (NOT TARGET _test.doxypress.open_pdf)
        assert_same("The target `_test.doxypress.open_pdf` was not created")
    endif()
endfunction()

test_create_targets()