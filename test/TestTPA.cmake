function(test_TPA_get_set_append)
    TPA_set(property "value")
    TPA_append(property "value2")
    TPA_get(property _new_value)
    assert_same("${_new_value}" "value;value2")
endfunction()

function(test_TPA_clear_scope)
    TPA_set(output-xml.generate-xml_INPUT GENERATE_XML)
    TPA_set(output-xml.generate-xml_SETTER "set_generate_xml")

    TPA_get(output-xml.generate-xml_INPUT _xml)
    assert_same("${_xml}" "GENERATE_XML")
    TPA_get(output-xml.generate-xml_SETTER _setter)
    assert_same("${_setter}" "set_generate_xml")
    TPA_clear_scope()
    TPA_get(output-xml.generate-xml_INPUT _xml)
    assert_same("${_xml}" "")
    TPA_get(output-xml.generate-xml_SETTER _setter)
    assert_same("${_setter}" "")
endfunction()

string(RANDOM LENGTH 5 _doxypress_cmake_uuid)
test_TPA_get_set_append()
test_TPA_clear_scope()
