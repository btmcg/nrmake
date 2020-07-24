include nrmake/env.mk
include nrmake/functions.mk
include nrmake/pattern_rules.mk
include nrmake/third_party.mk


# initialization
# ----------------------------------------------------------------------

# load modules (any subdirectory that contains a "Module.mk" file)
$(call load-modules)


# binary versioning
# ----------------------------------------------------------------------

# to disable any versioning information, comment out this line
include nrmake/version.mk


# rules and dependencies
# ----------------------------------------------------------------------

# generate all necessary rules
$(eval $(call build-rules,$(call get-all-modules)))


# recipes
# ----------------------------------------------------------------------

# necessary targets and phony targets
.PHONY: all benchmark clean dist distclean format list-modules tags test tidy $(call get-all-modules)

all: $(call get-all-modules)

dist: all | $(INC_DIR)
	$(make-dist)

clean:
	$(if $(wildcard $(call get-all-targets) $(call get-all-objs) $(call get-all-deps)),\
		$(RM) $(strip $(call get-all-targets)) $(call get-all-objs) $(call get-all-deps))
	$(if $(wildcard $(VERSION_FILE)),$(RM) $(VERSION_FILE))

distclean: clean
	$(if $(wildcard $(BIN_DIR)),\
		$(RM) $(BIN_DIR)/* && $(RMDIR) $(BIN_DIR))
	$(if $(wildcard $(INC_DIR)),\
		$(RM_RF) $(INC_DIR))
	$(if $(wildcard $(LIB_DIR)),\
		$(RM) $(LIB_DIR)/* && $(RMDIR) $(LIB_DIR))

format:
	@[ ! -d src       ] || find src       -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;
	@[ ! -d test      ] || find test      -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;
	@[ ! -d benchmark ] || find benchmark -type f -regex ".*\.[ch]\(pp\)?$$" -exec $(FORMAT) {} \;

tags:
	ctags --recurse src

benchmark: benchmark-runner
	./bin/$^

test: test-runner
	./bin/$^

tidy:
	$(run-clang-tidy)

list-modules:
	$(list-modules)

$(BIN_DIR):
	$(MKDIR) $(BIN_DIR)

$(INC_DIR):
	$(MKDIR) $(INC_DIR)

$(LIB_DIR):
	$(MKDIR) $(LIB_DIR)
