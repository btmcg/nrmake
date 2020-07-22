#￼Copyright(c) 2020-present, Brian McGuire.
# Distributed under the BSD-2-Clause
# (http://opensource.org/licenses/BSD-2-Clause)


# module-specific variables
# ----------------------------------------------------------------------
modules-locals := \
  MODULE_CFLAGS \
  MODULE_CPPFLAGS \
  MODULE_CXXFLAGS \
  MODULE_DEPS \
  MODULE_EXPORT_HEADERS \
  MODULE_EXPORT_HEADERS_PREFIX \
  MODULE_LDFLAGS \
  MODULE_LDLIBS \
  MODULE_LIBRARIES \
  MODULE_NAME \
  MODULE_OBJS \
  MODULE_PATH \
  MODULE_SOURCE_FILES \
  MODULE_TARGET


# ----------------------------------------------------------------------
# function : get-path
# returns  : the path of the current file
# usage    : $(call get-path)
# ----------------------------------------------------------------------
get-path = $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))


# ----------------------------------------------------------------------
# function : empty
# returns  : an empty macro
# usage    : $(empty)
# ----------------------------------------------------------------------
empty :=


# ----------------------------------------------------------------------
# function : space
# returns  : a single space
# usage    : $(space)
# ----------------------------------------------------------------------
space  := $(empty) $(empty)
space2 := $(space)$(space)


# ----------------------------------------------------------------------
# function : \n
# returns  : a newline
# usage    : \n
# ----------------------------------------------------------------------
define \n


endef


# ----------------------------------------------------------------------
# function : uniq
# returns  : a string with duplicate words removed
# usage    : $(call uniq,<string>)
# ----------------------------------------------------------------------
uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))


# ----------------------------------------------------------------------
# function : clear-vars
# returns  : nothing
# usage    : $(call clear-vars)
# rationale: undefines all MODULE_* variables
# note     : undefine was added in GNU Make v3.82
# ----------------------------------------------------------------------
clear-vars =\
  $(foreach var,$(modules-locals),\
    $(eval undefine $(var))\
  )


# ----------------------------------------------------------------------
# function : rwildcard
# arguments: 1: directory to start search in
#            2: pattern(s) to match
# returns  : all files matching pattern under directory
# usage    : $(call rwildcard,,*.cpp), $(call rwildcard,/tmp/,*.c *.cpp)
# rationale: recursively searchs each directory below $1 for filenames
#            matching pattern in $2
# ----------------------------------------------------------------------
rwildcard =\
  $(patsubst $1/%,%,\
    $(foreach directory,$(wildcard $1*),\
      $(call rwildcard,$(directory)/,$2)\
      $(filter $(subst *,%,$2),$(directory))\
    )\
  )


# ----------------------------------------------------------------------
# function : convert-c-cpp-suffix-to
# arguments: 1: list of files
#            2: suffix to change all .c and .cpp suffices to
# returns  : files from $1 with suffices changed
# usage    : $(call convert-c-cpp-suffix-to,<file1> <file2> <file3>,o)
# ----------------------------------------------------------------------
convert-c-cpp-suffix-to =\
  $(patsubst %.c,%.$2,\
    $(patsubst %.cpp,%.$2,$1))


# ----------------------------------------------------------------------
# function : get-all-deps
# returns  : every module's MODULE_DEPS
# usage    : $(call get-all-deps)
# ----------------------------------------------------------------------
get-all-deps =\
  $(foreach name,$(__all_modules),$(__modules.$(name).MODULE_DEPS))


# ----------------------------------------------------------------------
# function : get-all-modules
# returns  : every module's name
# usage    : $(call get-all-modules)
# note     : this exists simply to make the top-level Makefile more
#          : consistent in its usage of get-all-xxx functions
# ----------------------------------------------------------------------
get-all-modules = $(__all_modules)


# ----------------------------------------------------------------------
# function : get-all-objs
# returns  : every module's MODULE_OBJS
# usage    : $(call get-all-objs)
# ----------------------------------------------------------------------
get-all-objs =\
  $(foreach name,$(__all_modules),$(__modules.$(name).MODULE_OBJS))


# ----------------------------------------------------------------------
# function : get-all-targets
# returns  : every module's MODULE_TARGET
# usage    : $(call get-all-targets)
# ----------------------------------------------------------------------
get-all-targets =\
  $(foreach name,$(__all_modules),$(__modules.$(name).MODULE_TARGET))


# ----------------------------------------------------------------------
# function : load-modules
# returns  : nothing
# usage    : $(call load-modules)
# rationale: Initialization function for this build system. This
#            function simply includes all of the necessary Module.mk
#            files which provide the foundation for all of the pieces of
#            data needed to put together rules and recipes.
# note     : The default goal "all" needs to be declared here (before
#            any other goals) so that it is considered the main goal.
# ----------------------------------------------------------------------
load-modules =\
  $(eval all:)\
  $(eval include $(shell find . -name "Module.mk"))


# ----------------------------------------------------------------------
# function : add-executable-module
# arguments: 1: path to module's Module.mk file
# returns  : nothing
# usage    : $(call add-executable-module)
# rationale: used in Module.mk files to add an executable target to the
#            build system
# note     : this function requires MODULE_PATH to be set by caller
# ----------------------------------------------------------------------
add-executable-module =\
  $(eval MODULE_PATH := $1)\
  $(eval MODULE_NAME ?= $(notdir $(MODULE_PATH)))\
  $(eval __modules.$(MODULE_NAME).MODULE_TARGET := $(MODULE_PATH)/$(MODULE_NAME))\
  $(eval __modules.$(MODULE_NAME).MODULE_TYPE   := executable)\
  $(call _add-module,$(MODULE_NAME))


# ----------------------------------------------------------------------
# function : add-shared-library-module
# arguments: 1: path to module's Module.mk file
# returns  : nothing
# usage    : $(call add-shared-library-module)
# rationale: used in Module.mk files to add a shared library target to
#            the build system
# note     : this function requires MODULE_PATH to be set by caller
# ----------------------------------------------------------------------
add-shared-library-module =\
  $(eval MODULE_PATH := $1)\
  $(eval MODULE_NAME ?= $(notdir $(MODULE_PATH)))\
  $(eval __modules.$(MODULE_NAME).MODULE_TARGET := $(MODULE_PATH)/lib$(MODULE_NAME).so)\
  $(eval __modules.$(MODULE_NAME).MODULE_TYPE   := shared_library)\
  $(eval __modules.$(MODULE_NAME).MODULE_CPPFLAGS += -fPIC)\
  $(eval __modules.$(MODULE_NAME).MODULE_LDFLAGS  += -fPIC)\
  $(call _add-module,$(MODULE_NAME))


# ----------------------------------------------------------------------
# function : add-static-library-module
# arguments: 1: path to module's Module.mk file
# returns  : nothing
# usage    : $(call add-static-library-module)
# rationale: used in Module.mk files to add a static library target to
#            the build system
# note     : this function requires MODULE_PATH to be set by caller
# ----------------------------------------------------------------------
add-static-library-module =\
  $(eval MODULE_PATH := $1)\
  $(eval MODULE_NAME ?= $(notdir $(MODULE_PATH)))\
  $(eval __modules.$(MODULE_NAME).MODULE_TARGET := $(MODULE_PATH)/lib$(MODULE_NAME).a)\
  $(eval __modules.$(MODULE_NAME).MODULE_TYPE   := static_library)\
  $(call _add-module,$(MODULE_NAME))


# ----------------------------------------------------------------------
# function : _add-module
# arguments: 1: single module name to be added
# returns  : nothing
# usage    : $(call _add-module,<module>)
# rationale: internal function used for common add-module code used by
#            all of the different module types.
# ----------------------------------------------------------------------
_add-module =\
  $(if $(MODULE_SOURCE_FILES),\
    $(eval __local_src := $(addprefix $(MODULE_PATH)/,$(MODULE_SOURCE_FILES)))\
  ,\
    $(eval __local_src := $(wildcard $(MODULE_PATH)/*.cpp $(MODULE_PATH)/*.c))\
  )\
  $(if $(MODULE_EXPORT_HEADERS),\
    $(if $(MODULE_EXPORT_HEADERS_PREFIX),\
      $(eval __modules.$1.MODULE_EXPORT_HEADERS_PREFIX := $(MODULE_EXPORT_HEADERS_PREFIX))\
    ,\
      $(eval __modules.$1.MODULE_EXPORT_HEADERS_PREFIX := $(subst src/,,$(MODULE_PATH)))\
    )\
  )\
  $(eval __modules.$1.MODULE_CFLAGS         := $(MODULE_CFLAGS))\
  $(eval __modules.$1.MODULE_CPPFLAGS       := $(MODULE_CPPFLAGS))\
  $(eval __modules.$1.MODULE_CXXFLAGS       := $(MODULE_CXXFLAGS))\
  $(eval __modules.$1.MODULE_DEPS           := $(call convert-c-cpp-suffix-to,$(__local_src),d))\
  $(eval __modules.$1.MODULE_EXPORT_HEADERS := $(addprefix $(MODULE_PATH)/,$(MODULE_EXPORT_HEADERS)))\
  $(eval __modules.$1.MODULE_LDFLAGS        := $(MODULE_LDFLAGS))\
  $(eval __modules.$1.MODULE_LDLIBS         := $(addprefix -l,$(MODULE_LIBRARIES)) $(MODULE_LDLIBS))\
  $(eval __modules.$1.MODULE_LIBRARIES      := $(MODULE_LIBRARIES))\
  $(eval __modules.$1.MODULE_OBJS           := $(call convert-c-cpp-suffix-to,$(__local_src),o))\
  $(eval __modules.$1.MODULE_PATH           := $(MODULE_PATH))\
  $(eval __modules.$1.MODULE_SOURCE_FILES   := $(__local_src))\
  $(eval __all_modules += $1)\
  $(eval undefine __local_src)\
  $(call clear-vars)


# ----------------------------------------------------------------------
# function : build-module-rules
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-module-rules,<module_name>)
# rationale: generates rules for module
# ----------------------------------------------------------------------
build-module-rules =\
  $(eval __modules.$1.MODULE_LDFLAGS += -L$(LIB_DIR))\
  $(eval $1: $(__modules.$1.MODULE_TARGET))\
  $(eval $1: $(__modules.$1.MODULE_PATH)/Module.mk)


# ----------------------------------------------------------------------
# function : build-local-target-rules
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-local-target-rules,<module_name>)
# rationale: generates rules for module's MODULE_TARGET
# ----------------------------------------------------------------------
build-local-target-rules =\
  $(eval $(__modules.$1.MODULE_TARGET): $(__modules.$1.MODULE_OBJS))\
  $(eval $(__modules.$1.MODULE_TARGET): $(__modules.$1.MODULE_PATH)/Module.mk)\
  $(eval $(__modules.$1.MODULE_TARGET):| $(BIN_DIR) $(LIB_DIR))\
  $(foreach other_module,$(__modules.$1.MODULE_LIBRARIES),\
    $(eval $(__modules.$1.MODULE_TARGET): $(__modules.$(other_module).MODULE_TARGET))\
    $(eval $(__modules.$1.MODULE_TARGET): $(__modules.$(other_module).MODULE_PATH)/Module.mk)\
  )

# ----------------------------------------------------------------------
# function : build-internal-dependencies
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-internal-dependencies,<module_name>)
# rationale: internal dependencies are based on the values given in
#            MODULE_LIBRARIES, so for each module provided, append all
#            flags from that module to this module
#            Note that certain variables are uniq'd.
# ----------------------------------------------------------------------
build-internal-dependencies =\
  $(foreach other_module,$(__modules.$1.MODULE_LIBRARIES),\
    $(eval __modules.$1.MODULE_CPPFLAGS += $(__modules.$(other_module).MODULE_CPPFLAGS))\
    $(eval __modules.$1.MODULE_CFLAGS += $(__modules.$(other_module).MODULE_CFLAGS))\
    $(eval __modules.$1.MODULE_CXXFLAGS += $(__modules.$(other_module).MODULE_CXXFLAGS))\
    $(eval __modules.$1.MODULE_LDFLAGS += $(__modules.$(other_module).MODULE_LDFLAGS))\
    $(eval __modules.$1.MODULE_LDLIBS += $(__modules.$(other_module).MODULE_LDLIBS))\
    \
    $(eval __modules.$1.MODULE_CPPFLAGS := $(call uniq,$(__modules.$1.MODULE_CPPFLAGS)))\
    $(eval __modules.$1.MODULE_LDLIBS := $(call uniq,$(__modules.$1.MODULE_LDLIBS)))\
    $(eval __modules.$1.MODULE_LDFLAGS := $(call uniq,$(__modules.$1.MODULE_LDFLAGS)))\
  )

# ----------------------------------------------------------------------
# function : build-object-rules
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-object-rules,<module_name>)
# rationale: generates rules for each object file (*.o) in module's
#            MODULE_OBJS
# ----------------------------------------------------------------------
build-object-rules =\
  $(foreach source,$(__modules.$1.MODULE_SOURCE_FILES),\
    $(eval $(call convert-c-cpp-suffix-to,$(source),o): $(source) Makefile nrmake/env.mk nrmake/functions.mk nrmake/pattern_rules.mk nrmake/third_party.mk)\
    $(eval $(call convert-c-cpp-suffix-to,$(source),o): $(__modules.$1.MODULE_PATH)/Module.mk)\
    $(eval $(call convert-c-cpp-suffix-to,$(source),o): __local_cflags := $$(__modules.$1.MODULE_CFLAGS))\
    $(eval $(call convert-c-cpp-suffix-to,$(source),o): __local_cppflags := $$(__modules.$1.MODULE_CPPFLAGS))\
    $(eval $(call convert-c-cpp-suffix-to,$(source),o): __local_cxxflags := $$(__modules.$1.MODULE_CXXFLAGS))\
  )


# ----------------------------------------------------------------------
# function : build-rules
# arguments: 1: list of module names
# returns  : nothing
# usage    : $(call build-rules,<module_1> <module_2> <module_3> ...)
# rationale: Generates and invokes all of the rules needed for all
#            modules. Once all rules and dependencies have been
#            determined, all that is left to do is kick off the build.
# ----------------------------------------------------------------------
build-rules =\
  $(foreach name,$1,\
    $(call build-module-rules,$(name))\
    $(call build-local-target-rules,$(name))\
    $(call build-internal-dependencies,$(name))\
    $(call build-object-rules,$(name))\
    $(eval -include $(__modules.$(name).MODULE_DEPS))\
    \
    $(if $(filter executable,$(__modules.$(name).MODULE_TYPE)),\
      $(call build-executable,$(name))\
    )\
    $(if $(filter shared_library,$(__modules.$(name).MODULE_TYPE)),\
      $(call build-shared-library,$(name))\
    )\
    $(if $(filter static_library,$(__modules.$(name).MODULE_TYPE)),\
      $(call build-static-library,$(name))\
    )\
  )


# ----------------------------------------------------------------------
# function : build-executable
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-executable,<module_name>)
# rationale: generates recipe for module's MODULE_TARGET
# ----------------------------------------------------------------------
define build-executable
$(__modules.$1.MODULE_TARGET): __build_cmd := $$(call cmd-build,$1)
$(__modules.$1.MODULE_TARGET):
	$$(__build_cmd)
	$(CP) $(__modules.$1.MODULE_TARGET) $(BIN_DIR)/$(notdir $(__modules.$1.MODULE_TARGET))

endef


# ----------------------------------------------------------------------
# function : build-shared-library
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-shared-library,<module_name>)
# rationale: generates recipe for module's MODULE_TARGET
# ----------------------------------------------------------------------
define build-shared-library
$(__modules.$1.MODULE_TARGET): __build_cmd := $$(call cmd-build,$1)
$(__modules.$1.MODULE_TARGET):
	$$(__build_cmd)
	$(CP) $(__modules.$1.MODULE_TARGET) $(LIB_DIR)/$(notdir $(__modules.$1.MODULE_TARGET))

endef


# ----------------------------------------------------------------------
# function : build-static-library
# arguments: 1: module name
# returns  : nothing
# usage    : $(call build-static-library,<module_name>)
# rationale: generates recipe for module's MODULE_TARGET
# ----------------------------------------------------------------------
define build-static-library
$(__modules.$1.MODULE_TARGET): __build_cmd := $$(call cmd-build-static-library,$1)
$(__modules.$1.MODULE_TARGET):
	$$(__build_cmd)
	$(CP) $(__modules.$1.MODULE_TARGET) $(LIB_DIR)/$(notdir $(__modules.$1.MODULE_TARGET))

endef


# ----------------------------------------------------------------------
# function : cmd-build
# arguments: 1: module name
# returns  : full, executable, compilation/link line for executables and
#            shared libraries
# usage    : $(call cmd-build,<module_name>)
# note     : If there is a file in MODULE_SOURCE_FILES with an extension
#          : of ".cpp", then $(CXX) will be used to compile/link,
#          : otherwise, $(CC) will be used.
# ----------------------------------------------------------------------
cmd-build =\
  $(strip \
    $(if $(filter %.cpp,$(__modules.$1.MODULE_SOURCE_FILES)),\
      $(if $(filter executable,$(__modules.$1.MODULE_TYPE)),\
        $(call cmd-build-cpp-executable,$1)\
      )\
      $(if $(filter shared_library,$(__modules.$1.MODULE_TYPE)),\
        $(call cmd-build-cpp-shared-library,$1)\
      )\
      $(if $(filter static_library,$(__modules.$1.MODULE_TYPE)),\
        $(call cmd-build-static-library,$1)\
      )\
    ,\
      $(if $(filter %.c,$(__modules.$1.MODULE_SOURCE_FILES)),\
        $(if $(filter executable,$(__modules.$1.MODULE_TYPE)),\
          $(call cmd-build-c-executable,$1)\
        )\
        $(if $(filter shared_library,$(__modules.$1.MODULE_TYPE)),\
          $(call cmd-build-c-shared-library,$1)\
        )\
        $(if $(filter static_library,$(__modules.$1.MODULE_TYPE)),\
          $(call cmd-build-static-library,$1)\
        )\
      )\
    )\
  )


# ----------------------------------------------------------------------
# function : cmd-build-c-executable
# arguments: 1: module name
# returns  : full, executable, compilation/link line for executables
#            written in C.
# usage    : $(call cmd-build-c-executable,<module_name>)
# ----------------------------------------------------------------------
cmd-build-c-executable =\
  $(CC)\
  $(__modules.$1.MODULE_OBJS)\
  $(CPPFLAGS)\
  $(__modules.$1.MODULE_CPPFLAGS)\
  $(CFLAGS)\
  $(__modules.$1.MODULE_CFLAGS)\
  $(LDFLAGS)\
  $(__modules.$1.MODULE_LDFLAGS)\
  $(TARGET_ARCH)\
  $(LDLIBS)\
  $(__modules.$1.MODULE_LDLIBS)\
  -o $(__modules.$1.MODULE_TARGET)


# ----------------------------------------------------------------------
# function : cmd-build-c-shared-library
# arguments: 1: module name
# returns  : full, executable, compilation/link line for shared
#            libraries written in C.
# usage    : $(call cmd-build-c-shared-library,<module_name>)
# ----------------------------------------------------------------------
cmd-build-c-shared-library =\
  $(CC)\
  $(__modules.$1.MODULE_OBJS)\
  $(CPPFLAGS)\
  $(__modules.$1.MODULE_CPPFLAGS)\
  $(CFLAGS)\
  $(__modules.$1.MODULE_CFLAGS)\
  $(LDFLAGS)\
  $(__modules.$1.MODULE_LDFLAGS) -shared\
  $(TARGET_ARCH)\
  $(LDLIBS)\
  $(__modules.$1.MODULE_LDLIBS)\
  -o $(__modules.$1.MODULE_TARGET)


# ----------------------------------------------------------------------
# function : cmd-build-cpp-executable
# arguments: 1: module name
# returns  : full, executable, compilation/link line for executables
#            written in C++
# usage    : $(call cmd-build-cpp-executable,<module_name>)
# ----------------------------------------------------------------------
cmd-build-cpp-executable =\
  $(CXX)\
  $(__modules.$1.MODULE_OBJS)\
  $(CPPFLAGS)\
  $(__modules.$1.MODULE_CPPFLAGS)\
  $(CXXFLAGS)\
  $(__modules.$1.MODULE_CXXFLAGS)\
  $(LDFLAGS)\
  $(__modules.$1.MODULE_LDFLAGS)\
  $(TARGET_ARCH)\
  $(LDLIBS)\
  $(__modules.$1.MODULE_LDLIBS)\
  -o $(__modules.$1.MODULE_TARGET)


# ----------------------------------------------------------------------
# function : cmd-build-cpp-shared-library
# arguments: 1: module name
# returns  : full, executable, compilation/link line for shared
#            libraries written in C++
# usage    : $(call cmd-build-cpp-shared-library,<module_name>)
# ----------------------------------------------------------------------
cmd-build-cpp-shared-library =\
  $(CXX)\
  $(__modules.$1.MODULE_OBJS)\
  $(CPPFLAGS)\
  $(__modules.$1.MODULE_CPPFLAGS)\
  $(CXXFLAGS)\
  $(__modules.$1.MODULE_CXXFLAGS)\
  $(LDFLAGS)\
  $(__modules.$1.MODULE_LDFLAGS) -shared\
  $(TARGET_ARCH)\
  $(LDLIBS)\
  $(__modules.$1.MODULE_LDLIBS)\
  -o $(__modules.$1.MODULE_TARGET)


# ----------------------------------------------------------------------
# function : cmd-build-static-library
# arguments: 1: module name
# returns  : full command to produce a static lib
# usage    : $(call cmd-build-static-library,<module_name>)
# ----------------------------------------------------------------------
cmd-build-static-library =\
  $(AR)\
  $(__modules.$1.MODULE_TARGET)\
  $(__modules.$1.MODULE_OBJS)


# ----------------------------------------------------------------------
# function : run-clang-tidy
# arguments: none
# returns  : nothing
# rationale: calls the clang-tidy command on every available module
# usage    : $(run-clang-tidy)
# ----------------------------------------------------------------------
run-clang-tidy =\
  $(foreach name,$(filter-out benchmark-runner test-runner,$(__all_modules)),\
    $(if $(filter %.cpp,$(__modules.$(name).MODULE_SOURCE_FILES)),\
      $(call cmd-clang-tidy,$(name))\
      $(\n)\
    )\
  )


# ----------------------------------------------------------------------
# function : cmd-clang-tidy
# arguments: 1: module name
# returns  : full command to execute clang-tidy on a module's source
# usage    : $(call cmd-clang-tidy,<module_name>)
# ----------------------------------------------------------------------
cmd-clang-tidy =\
  $(TIDY)\
  $(__modules.$1.MODULE_SOURCE_FILES)\
  --\
  $(CPPFLAGS)\
  $(__modules.$1.MODULE_CPPFLAGS)\
  $(CXXFLAGS)\
  $(__modules.$1.MODULE_CXXFLAGS)


# ----------------------------------------------------------------------
# function : make-dist
# arguments: none
# returns  : nothing
# usage    : $(call cmd-clang-tidy,<module_name>)
# rationale: copies exported headers to include directory and creates a
#            tarball with bin, include, and lib directories ready for
#            distribution
# ----------------------------------------------------------------------
make-dist =\
  $(foreach name,$(__all_modules),\
    $(if $(__modules.$(name).MODULE_EXPORT_HEADERS),\
      $(eval __dest_dir := $(INC_DIR)/$(__modules.$(name).MODULE_EXPORT_HEADERS_PREFIX))\
      $(\n)\
      $(MKDIR) $(__dest_dir)\
      $(\n)\
      $(CP) $(__modules.$(name).MODULE_EXPORT_HEADERS) $(__dest_dir)\
      $(eval undefine __dest_dir)\
    )\
  )\
  $(\n)\
  $(CP) $(VERSION_FILE) $(INC_DIR)\
  $(\n)\
  $(TAR) --create --transform='s,^,$(shell basename $$(pwd))/,' --file=$(shell basename $$(pwd)).tar.zst  $(BIN_DIR) $(LIB_DIR) $(INC_DIR)


# debugging functions
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# function : list-modules
# returns  : nothing
# usage    : $(call list-modules)
# rationale: Useful for debugging. Prints all fields of all modules.
# ----------------------------------------------------------------------
list-modules =\
  $(info modules [$(__all_modules)])\
  $(info targets [$(call get-all-targets)])\
  $(info deps    [$(call get-all-deps)])\
  $(info objs    [$(call get-all-objs)])\
  $(info )\
  $(foreach name,$(__all_modules),\
    $(info $(name))\
    $(info $(space2)MODULE_CFLAGS                [$(__modules.$(name).MODULE_CFLAGS)])\
    $(info $(space2)MODULE_CPPFLAGS              [$(__modules.$(name).MODULE_CPPFLAGS)])\
    $(info $(space2)MODULE_CXXFLAGS              [$(__modules.$(name).MODULE_CXXFLAGS)])\
    $(info $(space2)MODULE_DEPS                  [$(__modules.$(name).MODULE_DEPS)])\
    $(info $(space2)MODULE_EXPORT_HEADERS        [$(__modules.$(name).MODULE_EXPORT_HEADERS)])\
    $(info $(space2)MODULE_EXPORT_HEADERS_PREFIX [$(__modules.$(name).MODULE_EXPORT_HEADERS_PREFIX)])\
    $(info $(space2)MODULE_LDFLAGS               [$(__modules.$(name).MODULE_LDFLAGS)])\
    $(info $(space2)MODULE_LDLIBS                [$(__modules.$(name).MODULE_LDLIBS)])\
    $(info $(space2)MODULE_LIBRARIES             [$(__modules.$(name).MODULE_LIBRARIES)])\
    $(info $(space2)MODULE_OBJS                  [$(__modules.$(name).MODULE_OBJS)])\
    $(info $(space2)MODULE_PATH                  [$(__modules.$(name).MODULE_PATH)])\
    $(info $(space2)MODULE_SOURCE_FILES          [$(__modules.$(name).MODULE_SOURCE_FILES)])\
    $(info $(space2)MODULE_TARGET                [$(__modules.$(name).MODULE_TARGET)])\
    $(info $(space2)MODULE_TYPE                  [$(__modules.$(name).MODULE_TYPE)])\
  )
