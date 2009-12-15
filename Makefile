all: main

%: %.pas *.pas
	fpc $<

clean:
	rm -fr *.o *.ppu

