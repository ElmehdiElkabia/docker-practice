APP := app
CXX := g++
CXXFLAGS := -Wall -Wextra 
SRC = src/main.cpp src/message.cpp

all: $(APP)

$(APP): $(SRC)
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -f $(APP)

.PHONY: all clean
