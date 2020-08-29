include nrmake/env.mk
include nrmake/functions.mk
include nrmake/pattern_rules.mk
include nrmake/third_party.mk


# initialization
# ----------------------------------------------------------------------

# load modules (any subdirectory that contains a "Module.mk" file)
$(load-modules)


# binary versioning
# ----------------------------------------------------------------------

# to disable any versioning information, comment out this line
include nrmake/version.mk


# rules and dependencies
# ----------------------------------------------------------------------

# generate all necessary rules
$(eval $(call build-rules,$(get-all-modules)))


# recipes
# ----------------------------------------------------------------------

# necessary targets and phony targets
.PHONY: all benchmark clean dist distclean format help list-modules tags test tidy $(get-all-modules)
.PHONY: $(get-all-modules)

## all  build all modules in tree
all: $(get-all-modules)

## dist  create tarball for distribution
dist: all | $(INC_DIR)
	$(make-dist)

## clean  remove all targets and object code
clean:
	$(if $(wildcard $(get-all-targets) $(get-all-objs)),  \
		$(RM) $(strip $(get-all-targets)) $(get-all-objs) \
	)

## distclean  remove all build artifacts, completely cleaning tree
distclean: clean
	$(if $(wildcard $(get-all-deps)),  \
		$(RM) $(strip $(get-all-deps)) \
	)
	$(if $(wildcard $(VERSION_FILE)), \
		$(RM) $(VERSION_FILE)         \
	)
	$(if $(wildcard $(BIN_DIR)),                  \
		$(RM) $(BIN_DIR)/* && $(RMDIR) $(BIN_DIR) \
	)
	$(if $(wildcard $(INC_DIR)), \
		$(RM_RF) $(INC_DIR)      \
	)
	$(if $(wildcard $(LIB_DIR)),                  \
		$(RM) $(LIB_DIR)/* && $(RMDIR) $(LIB_DIR) \
	)

## format  run clang-format on all c and cpp files in tree
format:
	@[ ! -d src       ] || find src       -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;
	@[ ! -d test      ] || find test      -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;
	@[ ! -d benchmark ] || find benchmark -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;

## help  show this message and exit
help: $(firstword $(MAKEFILE_LIST))
	$(info nrmake $(shell (cd nrmake && $(GIT_VERSION))))
	@printf "target arguments:\n"
	@sed --quiet --regexp-extended 's/^## ([-_a-zA-Z]+) +(.*)/    \1|\2/p' $< | sort | column --table --separator='|'
	@printf "module arguments:\n"
	@printf "    %s\n" $(get-all-modules) | sort

## tags  generate ctags
tags:
	ctags --recurse src

## benchmark  build benchmark-runner and execute it
benchmark: benchmark-runner
	./bin/$^

## test  build test-runner and execute it
test: test-runner
	./bin/$^

## tidy  run clang-tidy on all c and cpp files in tree
tidy:
	$(run-clang-tidy)

## list-modules  list all known modules in dependency tree
list-modules:
	$(list-modules)

$(BIN_DIR):
	$(MKDIR) $(BIN_DIR)

$(INC_DIR):
	$(MKDIR) $(INC_DIR)

$(LIB_DIR):
	$(MKDIR) $(LIB_DIR)
