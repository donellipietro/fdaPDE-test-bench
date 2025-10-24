
# Define commands ----
RSCRIPT := Rscript


# C++ compiler ----
CC = /opt/homebrew/bin/gcc-15
CXX = /opt/homebrew/bin/g++-15
CXXFLAGS = -O3 -Wno-psabi -std=c++20 -march=native \
  -I/Users/pietrodonelli/Documents/University/fdaPDE/fdaPDE-cpp \
  -I/Users/pietrodonelli/Documents/University/fdaPDE/fdaPDE-cpp/fdaPDE/core \
  -I/opt/homebrew/include/eigen3 \

SRC = cpp/$(MODEL)/main.cpp
TARGET = cpp/$(MODEL)/fit_model

$(TARGET): $(SRC)
	$(CXX) -o $@ $^ $(CXXFLAGS)


# Targets ----
.PHONY: help install install_femR build complile \
        clean_options clean_compliled clean  distclean \
        run_test run_test_parallel


# Default target ----
all: install build


# Installation targets ----
install_femR:
	@echo "\nInstalling femR..."
	@$(RSCRIPT) src/installation/install_femR.R
# install_fdaPDE:
# 	@echo "\nInstalling fdaPDE..."
# 	@$(RSCRIPT) src/installation/install_fdaPDE.R
install:  install_femR 
	@echo "\nInstallation completed.\n"


# Build target ----
build:
	@echo "\nCreating necessary directories..."
	@mkdir -p results
	@mkdir -p images
	@echo "Build completed.\n"
	
## Compile C++ model
# Usage: make compile MODEL=my_model
compile:
	@if [ -z "$(MODEL)" ]; then \
		echo "\nUsage: make compile MODEL=<model_name>"; \
		exit 1; \
	fi
	@if [ ! -d "cpp/$(MODEL)" ]; then \
		echo "\nError: model directory cpp/$(MODEL) not found."; \
		exit 1; \
	fi
	@echo "\n Compling cpp/$(MODEL)/main.cpp ..."
	@$(MAKE) $(TARGET) MODEL=$(MODEL)


# Clean targets ----

## Clean temporary files
clean_tmp:
	@$(RM) -r tmp/
	
## Clean compiled binaries
clean_compliled: 
	@$(RM) cpp/*/fit_model

## Clean temporary files, logs and R session files
clean: clean_tmp
	@echo "\nCleaning temporary files..."
	@$(RM) *.aux *.log *.pdf *.txt *.json
	@$(RM) .Rhistory
	@$(RM) .RData
	@echo "Cleanup completed.\n"
	
## Clean results and images of a specific test
# - usage: make clean_test TEST_SUITE=centering TEST_NAME=test1
clean_test:
	@if [ -z "$(TEST_SUITE)" ] || [ -z "$(TEST_NAME)" ]; then \
		echo "\nUsage: make clean_test TEST_SUITE=<suite> TEST_NAME=<test_name>\n"; \
		echo "Available TEST_SUITEs:"; \
		find tests -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | sed 's/^/- /'; \
		echo ""; \
		exit 0; \
	else \
		echo "\nCleaning results and images for test: $(TEST_NAME) from suite: $(TEST_SUITE)"; \
		$(RM) -r results/$(TEST_SUITE)/$(TEST_NAME); \
		$(RM) -r images/$(TEST_SUITE)/$(TEST_NAME); \
		echo "Cleanup completed for test: $(TEST_NAME)\n"; \
	fi
	
## DANGER ZONE: Full cleanup of all generated files
distclean: clean clean_compliled
	@echo "Attention! This will remove ALL the additional files and directories generated so far."
	@read -p "Are you sure you want to continue? [y/n]: " confirm && [ "$$confirm" = "y" ] || (echo "Cleanup aborted." && false)
	@echo "Removing additional generated files..."
	@$(RM) -r images/
	@$(RM) -r results/
	@echo "Additional cleanup completed.\n"

# Test targets ----

## Run all the batches of a test sequentially
# usage: make run_test TEST_SUITE=centering TEST_NAME=test1
run_test: build
	@if [ -z "$(TEST_SUITE)" ] || [ -z "$(TEST_NAME)" ]; then \
		echo "Usage: make run_test TEST_SUITE=<suite> TEST_NAME=<test_name>"; \
		echo ""; \
		echo "Available TEST_SUITEs:"; \
		find tests -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | sed 's/^/- /'; \
		echo ""; \
		exit 0; \
	else \
		echo "Running: $(TEST_NAME) from suite $(TEST_SUITE)"; \
		./run_tests.sh "$(TEST_SUITE)" "$(TEST_NAME)"; \
	fi
	
## Run all the batches of a test in parallel
# usage: make run_test_parallel TEST_SUITE=centering TEST_NAME=test1
run_test_parallel: build
	@if [ -z "$(TEST_SUITE)" ] || [ -z "$(TEST_NAME)" ]; then \
		echo "Usage: make run_test_parallel TEST_SUITE=<suite> TEST_NAME=<test_name>"; \
		echo ""; \
		echo "Available TEST_SUITEs:"; \
		find tests -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | sed 's/^/- /'; \
		echo ""; \
		exit 0; \
	else \
		echo "Running: $(TEST_NAME) from suite $(TEST_SUITE)"; \
		./run_tests_parallel.sh "$(TEST_SUITE)" "$(TEST_NAME)"; \
	fi
	
	
## Show available targets and descriptions
# Pretty printing for help (tweak width/color as you like)
HELP_FMT ?= \033[36m- %-24s\033[0m %s\n
help:
	@echo "\nAvailable targets:"
	@awk -v fmt="$(HELP_FMT)" '\
/^[a-zA-Z0-9_.-]+:.*##/ { \
  line=$$0; \
  tgt=line; sub(/:.*/,"",tgt); \
  desc=line; sub(/.*##[[:space:]]*/,"",desc); \
  printf fmt, tgt, desc; \
  next \
} \
/^##/ { \
  line=$$0; sub(/^##[[:space:]]*/,"",line); \
  if (desc) desc = desc " " line; else desc = line; \
  next \
} \
/^[a-zA-Z0-9_.-]+:/ { \
  if (desc) { \
    tgt=$$0; sub(/:.*/,"",tgt); \
    printf fmt, tgt, desc; \
    desc=""; \
  } \
  next \
} \
' $(MAKEFILE_LIST)
	@echo ""