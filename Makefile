all: asciibattle

asciibattle: *.pas listofinteger.pas
	fpc $<

listofinteger.pas: list.pas.in
	sed -e 's/_X_/Integer/g' list.pas.in > listofinteger.pas

clean:
	rm -fr *.o *.ppu


