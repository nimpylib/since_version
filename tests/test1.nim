
import std/unittest

import since_version

const
  PyMajor = 3
  PyMinor = 10
  PyPatch = 13
gen_since py, PyMajor, PyMinor, PyPatch

test "expr":
  check pysince(3.15, false, true)

