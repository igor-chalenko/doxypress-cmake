==========
What is it
==========

This is a CMake package that makes it easy to set up API documentation
generation via Doxypress_. At the bare minimum, all one needs to do is
to import this package and then call `doxypress_add_docs`:

.. code-block:: cmake

  find_package(DoxypressCMake)
  doxypress_add_docs(INPUT_TARGET target_in_the_need_of_docs)

The above code will generate a `Doxypress`' project file under
``CMAKE_CURRENT_BINARY_DIR``. Documentation will be generated
under ``CMAKE_CURRENT_BINARY_DIR``/``doxypress-generated``.

.. _Doxypress: https://www.copperspice.com/docs/doxypress/index.html

====================
A few usage examples
====================

.. code-block:: cmake

  find_package(DoxypressCMake)
  if(TARGET Doxypress::doxypress)
    # 1) Default settings, there must be a target named `${PROJECT_NAME}`:
    doxypress_add_docs()
    # 2) Default settings, custom project file given:
    doxypress_add_docs(PROJECT_FILE docs/Doxypress.json.in)
    # 3) Obtain input sources from the given target's include directories:
    doxypress_add_docs(INPUT_TARGET target_name)
  endif()

============
Installation
============

`DoxypressCMake` can be installed as a normal CMake package:

.. code-block:: bash

   git clone git@github.com:igor-chalenko/doxypress-cmake.git
   cd doxypress-cmake
   mkdir build && cd build
   # this will run the tests and create install commands
   cmake ..
   # install to a local directory
   make install # (you probably need to prepend `sudo` on Linux)

Alternatively, add the repository as git submodule:

.. code-block:: bash

   mkdir externals
   git submodule git@github.com:igor-chalenko/doxypress-cmake.git externals/doxypress-cmake

Then add externals/doxypress-cmake/cmake to your `CMAKE_MODULE_PATH`:

.. code-block:: cmake

   list(APPEND CMAKE_MODULE_PATH
        "${CMAKE_SOURCE_DIR}/externals/doxypress-cmake/cmake")

It's also possible to integrate package files into your repository directly.

=====
Usage
=====

.. code-block:: cmake

  find_package(doxypress-cmake)
  if(TARGET Doxypress::doxypress)
    doxypress_add_docs(
        PROJECT_FILE
        INPUT_TARGET
        EXAMPLES
        INPUTS
        INSTALL_COMPONENT
        GENERATE_HTML
        GENERATE_LATEX
        GENERATE_PDF
        GENERATE_XML
        OUTPUT_DIRECTORY)
  endif()

Refer to the :ref:`Public functions and variables` section for details.
