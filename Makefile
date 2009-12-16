all: asciibattle

asciibattle: asciibattle.pas battlefield.pas physics.pas config.pas staticconfig.pas listofinteger.pas
	fpc asciibattle.pas

listof%.pas: list.pas.in
	sed -e 's/_X_/Integer/g' list.pas.in > $@

clean:
	rm -fr *.o *.ppu


