cmake_minimum_required(VERSION 3.3)
project(DoxypressCMake VERSION 0.0.1 DESCRIPTION "Doxypress module for CMake")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/externals/json-cmake")

add_subdirectory(test)
add_subdirectory(doc)

include(cmake/InstallBasicPackageFiles.cmake)

if (${CMAKE_VERSION} VERSION_LESS 3.14)
    if (NOT DEFINED CMAKE_INSTALL_LIBDIR)
        unset(CMAKE_INSTALL_LIBDIR)
        include(GNUInstallDirs)
    endif()
    set(_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
    install_basic_package_files(${PROJECT_NAME}
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY AnyNewerVersion
            #ARCH_INDEPENDENT
            NO_EXPORT
            EXTRA_PATH_VARS_SUFFIX MODULE_DIR
            NO_CHECK_REQUIRED_COMPONENTS_MACRO)
else()
    if (NOT DEFINED CMAKE_INSTALL_DATADIR)
        unset(CMAKE_INSTALL_DATADIR)
        include(GNUInstallDirs)
    endif()
    set(_DESTINATION ${CMAKE_INSTALL_DATADIR}/cmake/${PROJECT_NAME})
    install_basic_package_files(${PROJECT_NAME}
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY AnyNewerVersion
            ARCH_INDEPENDENT
            NO_EXPORT
            EXTRA_PATH_VARS_SUFFIX MODULE_DIR
            NO_CHECK_REQUIRED_COMPONENTS_MACRO)
endif()

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
        DESTINATION ${_DESTINATION})
