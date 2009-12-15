all: asciibattle

%: %.pas *.pas
	fpc $<

clean:
	rm -fr *.o *.ppu

