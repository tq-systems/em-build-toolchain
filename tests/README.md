# Tests

Python unit tests of the scripts in docker/usr/local/bin. Each test file runs on its own, as the
.python-unit-tests job of public/build/base calls it:

    ./tests/test_sbom.py
