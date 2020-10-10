function(test_create_targets)
    _JSON_set(doxypress.general.output-dir "${CMAKE_CURRENT_BINARY_DIR}")
    _JSON_set(doxypress.output-html.generate-html true)
    _JSON_set(doxypress.output-latex.generate-latex true)
    TPA_set(GENERATE_PDF true)

    add_custom_target(_test COMMAND "${CMAKE_COMMAND} --version")
    TPA_set(INPUT_TARGET _test)
    TPA_set(TARGET_NAME "doxypress_docs")
    configure_file(DoxypressTest1.json
            ${CMAKE_CURRENT_BINARY_DIR}/DoxypressTest1.json @ONLY)
    _doxypress_targets_create(${PROJECT_SOURCE_DIR}/DoxypressTest1.json
            ${CMAKE_CURRENT_BINARY_DIR}/DoxypressTest1.json)
    _doxypress_targets_open_files(doxypress_docs "${CMAKE_CURRENT_BINARY_DIR}")

    if (NOT TARGET doxypress_docs)
        assert_same("doxypress target `doxypress_docs` was not created")
    endif()
    if (NOT TARGET doxypress_docs.open_html)
        assert_same("The target `doxypress_docs.open_html` was not created" "")
    endif()
    if (NOT TARGET doxypress_docs.open_latex)
        assert_same("The target `doxypress_docs.open_latex` was not created" "")
    endif()
    if (NOT TARGET doxypress_docs.open_pdf)
        assert_same("The target `doxypress_docs.open_pdf` was not created" "")
    endif()
endfunction()

test_create_targets()