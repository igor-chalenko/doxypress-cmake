# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))

# -- Project information -----------------------------------------------------

project = '${PROJECT_NAME}'
copyright = '2020, Igor Chalenko'
author = 'Igor Chalenko'

# The full version, including alpha/beta/rc tags
release = '${PROJECT_VERSION}'

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.autosectionlabel',
    # 'sphinx.ext.pngmath',
    'sphinx.ext.todo',
    'breathe',
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'

html_theme_options = {
    'display_version': True,
    # Toc options
    'sticky_navigation': True,
    'navigation_depth': 4,
    'style_nav_header_background': '#202020',
}

html_css_files = [
    'css/hydejack.css',
]

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['${CMAKE_CURRENT_SOURCE_DIR}/source/_static']

breathe_projects = {"${PROJECT_NAME}": "${CMAKE_CURRENT_BINARY_DIR}/doxypress-generated/xml"}
breathe_default_project = "${PROJECT_NAME}"
