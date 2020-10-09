function(test_input_directories_full_3)
    set("output-latex.generate-latex" false)
    set(LATEX_FOUND true)
    doxypress_add_docs(
            INPUT_TARGET main
            INPUTS dir1 dir2 GENERATE_LATEX)

    _doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)
    _JSON_get("doxypress.${_DOXYPRESS_INPUT_SOURCE}" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
    _JSON_get("doxypress.output-latex.generate-latex" _latex)
    assert_same(${_latex} true)
    unset(LATEX_FOUND)
endfunction()

function(test_logging)
    _doxypress_params_init()
    _doxypress_inputs_parse(INPUT_TARGET main GENERATE_XML)
    _doxypress_project_load(../cmake/DoxypressCMake.json)
    _doxypress_project_update()
    _doxypress_project_save(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)

    TPA_get("histories" _histories)
    foreach(_property ${_histories})
        TPA_get(history.${_property} _messages)
        _doxypress_log(INFO "actions for ${_property}: ====")
        foreach(_message ${_messages})
            _doxypress_log(INFO ${_message})
        endforeach()
        _doxypress_log(INFO "====")
    endforeach()
    TPA_clear_scope()
endfunction()

test_input_directories_full_3()
# test_logging()