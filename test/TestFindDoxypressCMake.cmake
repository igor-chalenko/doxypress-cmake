include(../cmake/FindDoxypressCMake.cmake)

if (NOT TARGET Doxypress::doxypress)
    assert_same("Doxypress imported target not found" "")
endif()

if (NOT TARGET Doxypress::dot)
    assert_same("Dot imported target not found" "")
endif()

if (TARGET Doxypress::dia)
    assert_same("Dia imported target found, but shouldn't be" "")
endif()

assert_same(${DOXYPRESS_VERSION} "1.4.0")