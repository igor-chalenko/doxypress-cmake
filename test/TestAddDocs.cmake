function(test_input_directories_full_3)
    set("output-latex.generate-latex" false)
    doxypress_add_docs(
            INPUT_TARGET main
            INPUTS dir1 dir2 GENERATE_LATEX)

    doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)
    JSON_get("doxypress.input.input-source" _inputs)
    assert_same("${_inputs}"
            "${CMAKE_CURRENT_SOURCE_DIR}/dir1;${CMAKE_CURRENT_SOURCE_DIR}/dir2")
endfunction()

function(test_logging)
    doxypress_params_init()
    doxypress_params_parse(INPUT_TARGET main GENERATE_XML)
    doxypress_project_load(../cmake/DoxypressCMake.json)
    doxypress_project_update()
    doxypress_project_save(${CMAKE_CURRENT_BINARY_DIR}/DoxypressCMake.json)

    TPA_get("histories" _histories)
    foreach(_property ${_histories})
        TPA_get(history.${_property} _messages)
        doxypress_log(INFO "actions for ${_property}: ====")
        foreach(_message ${_messages})
            doxypress_log(INFO ${_message})
        endforeach()
        doxypress_log(INFO "====")
    endforeach()
    TPA_clear_scope()
endfunction()

test_input_directories_full_3()
set(DOXYPRESS_INFO ON)
# test_logging()