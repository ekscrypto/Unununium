.PHONY: all clean

all: e2u3map

e2u3map: e2u3map.cxx
	g++ -Wall -O2 e2u3map.cxx -o e2u3map
	strip e2u3map

clean:
	rm -f e2u3map
