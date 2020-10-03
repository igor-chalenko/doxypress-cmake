function(test__JSON_format)
    _JSON_format(ON _var1)
    _JSON_format(true _var2)
    _JSON_format(on _var3)
    _JSON_format(TRUE _var4)
    assert_same(${_var1} true)
    assert_same(${_var2} true)
    assert_same(${_var3} true)
    assert_same(${_var4} true)

    _JSON_format(OFF _var1)
    _JSON_format(false _var2)
    _JSON_format(off _var3)
    _JSON_format(FALSE _var4)
    assert_same(${_var1} false)
    assert_same(${_var2} false)
    assert_same(${_var3} false)
    assert_same(${_var4} false)

    _JSON_format(42 _var1)
    assert_same(${_var1} 42)
    _JSON_format("four" _var2)
    _JSON_format("" _var3)
    assert_same(${_var3} "\"\"")
    _JSON_format("\"four\"" _var4)
    assert_same(${_var4} "\"four\"")
endfunction()

function(test__JSON_get)
    _doxypress_project_load(DoxypressTest1.json)

    _JSON_get("doxypress.source.suffix-exclude-navtree" _property)
    assert_list_contains("${_property}" txt)
    assert_list_contains("${_property}" doc)
    assert_list_contains("${_property}" md)
    assert_list_contains("${_property}" markdown)
    assert_list_contains("${_property}" dox)

    _JSON_get("doxypress.source.inline-source" _property)
    assert_same("${_property}" false)
    TPA_clear_scope()
endfunction()

function(test__JSON_serialize)
    _doxypress_project_load(${CMAKE_CURRENT_SOURCE_DIR}/DoxypressTest1.json)
    TPA_get(${_DOXYPRESS_PROJECT_KEY} _variables)
    set(_new_value x1 x2 x3)
    _JSON_set("doxypress.source.suffix-exclude-navtree" "${_new_value}")
    _JSON_set("doxypress.source.inline-source" true)
    set(input.input-source "include10;include11")
    _doxypress_log(DEBUG "trying to override inputs via ${input.input-source}")
    _JSON_serialize("${_variables}" _json_document)

    # re-parse without saving
    sbeParseJson(doxypress _json_document)
    foreach (_property ${doxypress})
        TPA_set(${_property} "${${_property}}")
    endforeach ()
    TPA_set(_DOXYPRESS_PROJECT_KEY "${doxypress}")
    _JSON_get("doxypress.source.suffix-exclude-navtree" _new_value)
    assert_same("${_new_value}" "x1;x2;x3")
    _JSON_get("doxypress.source.inline-source" _new_value)
    assert_same(${_new_value} true)
    _JSON_get("doxypress.input.input-source" _input_source)
    assert_same("${_input_source}" "include2;include3")
    TPA_clear_scope()
endfunction()

function(test__JSON_set)
    _doxypress_project_load(DoxypressTest1.json)
    set(_new_value x1 x2 x3)
    _JSON_set("doxypress.source.suffix-exclude-navtree" "${_new_value}")
    _JSON_set("doxypress.source.inline-source" true)
    _JSON_set(OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    _doxypress_project_save(${CMAKE_CURRENT_BINARY_DIR}/doxypress.test.json)

    _doxypress_project_load(${CMAKE_CURRENT_BINARY_DIR}/doxypress.test.json)
    _JSON_get("doxypress.source.inline-source" _property)
    assert_same("${_property}" true)
    _JSON_get("doxypress.source.suffix-exclude-navtree" _property)
    assert_list_contains("${_property}" x1)
    assert_list_contains("${_property}" x2)
    TPA_clear_scope()
endfunction()

# test__JSON_format()
# test__JSON_get()
# test__JSON_set()
test__JSON_serialize()
