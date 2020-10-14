Frequently asked questions
--------------------------

-----------------------------------------------------------
This looks rather complicated. Shouldn't things be simpler?
-----------------------------------------------------------
A lot of complexity comes from the fact that the package needs to work with
JSON. Thus formatting the project file involves full parse/serialize cycle.
Another thing is the declarative (and thus customizable) description of actions
to perform.

------------------------------------
What are the benefits of using this?
------------------------------------
The more requirements are imposed on the documentation, the more difficult it is
to manage them. Not all of those requirements are manageable via simple
``configure_file`` -> ``doxypress`` sequence. The author finds it convenient
to not have a project file for every documented target; relative paths can be
used when needed; generated documentation can be quickly opened for reviewing;
per-project customization is easy, just to name a few.