#￼Copyright(c) 2020-present, Brian McGuire.
# Distributed under the BSD-2-Clause
# (http://opensource.org/licenses/BSD-2-Clause)


# third party libs
# ----------------------------------------------------------------------

CATCH := third_party/catch2/2.12.2/single_include
use-catch = $(eval LOCAL_CPPFLAGS += -isystem$(CATCH))

FMT := third_party/fmt/6.2.1
use-fmt = $(eval LOCAL_CPPFLAGS += -DFMT_HEADER_ONLY -isystem$(FMT)/include)

ifeq ($(COMPILER),gcc)
  GOOGLE_BENCHMARK := third_party/google-benchmark-gcc/1.5.1
else
  GOOGLE_BENCHMARK := third_party/google-benchmark-clang/1.5.1
endif
use-google-benchmark =\
  $(eval LOCAL_CPPFLAGS += -isystem$(GOOGLE_BENCHMARK)/include)\
  $(eval LOCAL_LDFLAGS += -L$(GOOGLE_BENCHMARK)/lib -Wl,-rpath -Wl,$(GOOGLE_BENCHMARK)/lib)\
  $(eval LOCAL_LDLIBS += -lbenchmark)
