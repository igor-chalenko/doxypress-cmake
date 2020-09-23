cmake_minimum_required(VERSION 3.3)
project(DoxypressCMake VERSION 0.0.1 DESCRIPTION "Doxypress module for CMake")

add_subdirectory(test)


include(cmake/InstallBasicPackageFiles.cmake)
include(GNUInstallDirs)

install_basic_package_files(${PROJECT_NAME}
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
        ARCH_INDEPENDENT
        NO_EXPORT
        EXTRA_PATH_VARS_SUFFIX MODULE_DIR
        NO_CHECK_REQUIRED_COMPONENTS_MACRO)

if (DEFINED CMAKE_INSTALL_DATADIR AND CMAKE_INSTALL_DATADIR)
    set(config_install_dir "${CMAKE_INSTALL_DATADIR}/cmake/${PROJECT_NAME}")

    install(FILES
            cmake/DoxypressCMake.cmake
            DESTINATION ${config_install_dir})
else()
    message(WARNING "CMAKE_INSTALL_DATADIR is required (install step skipped).")
endif()

