APP := app
CXX := g++
CXXFLAGS := -Wall -Wextra -Werror -std=c++17
SRC = src/main.cpp

all: $(APP)

$(APP): $(SRC)
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -f $(APP)

.PHONY: all clean
