Components
----------

.. image:: _static/img/components.png

* ``AddDocs`` processes input arguments and then delegates the work to
  the downstream modules
* ``ProjectFunctions`` module implements project file manipulation functions
* ``CMakeTargets`` module creates targets as requested by inputs: `DoxyPress`
  target, open targets for every generated format, and install commands
* ``Interpreter`` module generates the processed project file
* ``JSONFunctions`` module implements "low-level" JSON access functions
* ``TPA`` module implements :ref:`TPA scopes<TPA scope>`
* ``Logging`` module provides functions useful for debugging
