# Directories
FDAPDECPP_DIR = /Users/marcogalliani/Projects/fdaPDE-cpp
EIGEN_DIR = /opt/homebrew/include/eigen3
NLOHMAN_JSON_DIR = /Applications/json/single_include

# Compiler
CXX = g++-14

# Source
SRC = main.cpp

# Include paths
INCLUDES = \
  -I$(FDAPDECPP_DIR)/fdaPDE/core \
  -I$(FDAPDECPP_DIR) \
  -I$(EIGEN_DIR) \
  -I$(NLOHMAN_JSON_DIR)

# Flags
RELEASE_FLAGS = -O3 -std=c++20 -march=native -s $(INCLUDES)
DEBUG_FLAGS = -g -O0 -std=c++20 -arch arm64 $(INCLUDES)

# Targets
TARGET = frpde-old
DEBUG_TARGET = frpde-old-debug

# Default rule (release)
all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) -o $@ $^ $(RELEASE_FLAGS)

# Debug rule
debug: $(DEBUG_TARGET)

$(DEBUG_TARGET): $(SRC)
	$(CXX) -o $@ $^ $(DEBUG_FLAGS)

# Clean rule
clean:
	rm -f $(TARGET) $(DEBUG_TARGET)
