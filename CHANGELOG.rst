2.0.0 - 2020-07-17
------------------
* Make fmt v7.0.0 default in ``third_party.mk``.
* [breaking change] Rename all ``LOCAL_*`` variables to ``MODULE_*``,
  which also involved changing ``LOCAL_MODULE`` to ``MODULE_NAME``.


1.0.1 - 2020-06-11
------------------

* Add ``VERSION_FILE`` as a dependency to ``tidy`` target.
* Write ``VERSION_FILE`` in a single ``sh`` command to avoid
  race-conditions.


1.0.0 - 2020-06-09
------------------

* First "official" release.
