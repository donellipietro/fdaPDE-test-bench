# Compiler and flags
CXX = g++-14
CXXFLAGS = -O3 -std=c++20 -march=native \
  -I/Users/marcogalliani/Projects/fdaPDE-cpp \
  -I/Users/marcogalliani/Projects/fdaPDE-cpp/fdaPDE/core \
  -I/opt/homebrew/include/eigen3 \
  -I/Applications/json/single_include

# Target and source
TARGET = fpca-na
SRC = main.cpp

# Default rule
all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) -o $@ $^ $(CXXFLAGS)

# Clean rule
clean:
	rm -f $(TARGET)
