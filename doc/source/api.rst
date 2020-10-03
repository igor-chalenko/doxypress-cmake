Public functions and variables
==============================

==================
FindDoxypressCMake
==================

This module looks for `Doxypress` and some optional tools it supports. These
tools are enabled as components in the `find_package()` command:

* `dot`

  Graphviz dot utility used to render various graphs.

* `mscgen`

  Message Chart Generator utility used by Doxygen’s `msc` and `mscfile`
  commands;

* `dia`

  `Dia` the diagram editor used by Doxygen’s `diafile` command.

**Examples**

.. code-block:: cmake

   # Require dot, treat the other components as optional
   find_package(Doxygen REQUIRED dot OPTIONAL_COMPONENTS mscgen dia)

The following variables are defined by this module:
 * `DOXYPRESS_FOUND`
   True if the doxygen executable was found.
 * `DOXYGEN_VERSION`
   The version reported by doxypress --version.

The module defines IMPORTED targets for `Doxypress` and each component found.
The following import targets are defined if their corresponding executable
could be found (the component import targets will only be defined if that
component was requested):

 * `Doxypress::doxypress`
 * `Doxypress::dot`
 * `Doxypress::mscgen`
 * `Doxypress::dia`

==================
doxypress_add_docs
==================

# .. doxygenfunction:: doxypress_add_docs
   :project: DoxypressCMake

.. code-block:: cmake

    doxypress_add_docs(
        PROJECT_FILE
        INPUT_TARGET
        INPUTS
        INSTALL_COMPONENT
        EXAMPLE_DIRECTORIES
        GENERATE_HTML
        GENERATE_XML
        GENERATE_LATEX
        GENERATE_PDF
        OUTPUT_DIRECTORY
        STRIP_FROM_INC_PATH
        STRIP_FROM_PATH
    )

Performs the following tasks:

* Creates a target `${INPUT_TARGET}.doxypress` to run `Doxypress`; here
  `INPUT_TARGET` is the argument, given to this function, or its default value
  `${PROJECT_NAME}` if none given.

* Creates targets to open the generated documentation
  (`index.html`, 'refman.tex' or `refman.pdf`). An application that is
  configured to open the files of corresponding type is used.

* Adds the generated files to the `install` target, if a non-empty value
  of `INSTALL_COMPONENT` was given.

There are three sources of the configuration values:
* input arguments provided by the CMake user;
* defaults set by `cmake-doxypress`;
* non-empty values in the provided doxypress project file.

The order of evaluation is: `inputs` -> `PROJECT_FILE` -> `cmake-doxypress`.
That is, the logic of evaluation is as follows:

* Existing `CMake` variables will not be reset to default or read from
   `PROJECT_FILE`; if a variable is already defined, its value in
   `PROJECT_FILE` is ignored;
* if a property is in the list of unconditionally set properties (see below),
  its value in the project file is ignored;
* if none of the above holds, the property's value is looked up in
  the project file (either given or defaulted); if it's not empty, there's
  nothing to do; otherwise, the property gets a default value.

----------
Parameters
----------

**PROJECT_FILE**
    JSON project file that `Doxypress` uses as input. Antwerp will read
    this file during CMake configuration phase, update it accordingly, write
    the updated file back, and use the result as actual configuration. See
    :ref:`Algorithm description` for a detailed description of what the package
    does.

    Defaults to `DoxypressAddDocs.json`, provided with the package.

**INPUT_TARGET**
    This target's property `INTERFACE_INCLUDE_DIRECTORIES` determines the input
    sources in the generated project file.
    Default is `${PROJECT_NAME}` if such target exists, empty otherwise.

**INPUTS**
    A list of files and directories to be processed by Doxypress; takes priority
    over `INPUT_TARGET`.

**INSTALL_COMPONENT**
    If specified, an installation command for generated docs will be added to
    the `install` target; the input parameter is used as the component name for
    the generated files.

**OUTPUT_DIRECTORY**
     The base directory for all the generated documentation files.
     Default is `doxypress-generated`.

