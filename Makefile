# Define the Rscript command
RSCRIPT := Rscript

# Targets
.PHONY: install build install_femR clean distclean \
        tests test_example test_centering \
        test_example_parallel tests_parallel \
        clean_options run_all_centering_tests run_test

# Default target
all: build

# Installation targets
install_femR:
	@echo "Installing femR..."
	@$(RSCRIPT) src/installation/install_femR.R

install:  install_femR
	@echo "Installation completed."

# Build target
build:
	@echo "Creating necessary directories..."
	@mkdir -p data
	@mkdir -p results
	@mkdir -p images
	@echo "Build completed."

# Clean targets
clean_options:
	@$(RM) -r queue/
	@$(RM) -r logs/

clean: clean_options
	@echo "Cleaning temporary files..."
	@$(RM) *.aux *.log *.pdf *.txt *.json
	@$(RM) .Rhistory
	@$(RM) .RData
	@echo "Cleanup completed."
	
distclean: clean
	@echo "Attention! This will remove additional generated files."
	@read -p "Are you sure you want to continue? [y/n]: " confirm && [ "$$confirm" = "y" ] || (echo "Cleanup aborted." && false)
	@echo "Removing additional generated files..."
	@$(RM) -r images/
	@$(RM) -r results/
	@echo "Additional cleanup completed."
	
# Clean results and images of a specific test
# usage: make clean_test TEST_SUITE=centering TEST_NAME=test1
clean_test:
	@if [ -z "$(TEST_SUITE)" ] || [ -z "$(TEST_NAME)" ]; then \
		echo "Usage: make clean_test TEST_SUITE=<suite> TEST_NAME=<test_name>"; \
		exit 1; \
	fi
	@echo "Cleaning results and images for test: $(TEST_NAME) from suite: $(TEST_SUITE)"
	@$(RM) -r results/$(TEST_SUITE)/$(TEST_NAME)
	@$(RM) -r images/$(TEST_SUITE)/$(TEST_NAME)
	@echo "Cleanup completed for test: $(TEST_NAME)"

# Test targets
# usage: make run_test TEST_SUITE=centering TEST_NAME=test1
# Run a specific test (e.g. make run_test TEST_SUITE=centering TEST_NAME=centering_test1_us_0900_0800_0030_0.5)
run_test:
	@if [ -z "$(TEST_SUITE)" ] || [ -z "$(TEST_NAME)" ]; then \
		echo "Usage: make run_test TEST_SUITE=<suite> TEST_NAME=<test_name>"; \
		exit 1; \
	fi
	@echo "Running test: $(TEST_NAME) from suite: $(TEST_SUITE)"
	@./run_tests.sh $(TEST_SUITE) $(TEST_NAME)
