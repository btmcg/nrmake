# Copyright(c) 2020-present, Brian McGuire.
# Distributed under the BSD-2-Clause
# (http://opensource.org/licenses/BSD-2-Clause)


# third party libs
# ----------------------------------------------------------------------

CATCH := third_party/catch2/2.13.10/single_include
use-catch = $(eval MODULE_CPPFLAGS += -isystem$(CATCH))

FMT := third_party/fmt/7.1.0
use-fmt = $(eval MODULE_CPPFLAGS += -DFMT_HEADER_ONLY -isystem$(FMT)/include)

ifeq ($(COMPILER),gcc)
  GOOGLE_BENCHMARK := third_party/google-benchmark-gcc/1.9.4
else
  GOOGLE_BENCHMARK := third_party/google-benchmark-clang/1.9.4
endif
use-google-benchmark =                                                                       \
  $(eval MODULE_CPPFLAGS += -isystem$(GOOGLE_BENCHMARK)/include)                             \
  $(eval MODULE_LDFLAGS += -L$(GOOGLE_BENCHMARK)/lib -Wl,-rpath -Wl,$(GOOGLE_BENCHMARK)/lib) \
  $(eval MODULE_LDLIBS += -lbenchmark)
