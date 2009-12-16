all: asciibattle

asciibattle: asciibattle.pas battlefield.pas physics.pas physicstypes.pas config.pas staticconfig.pas listofrocket.pas
	fpc asciibattle.pas

listof%.pas: list.pas.in
	sed -e 's/_X_/'`echo $@ | sed -e 's/listof\([^.]\)\([^.]\+\)\.pas/\U\1\L\2/'`'/g' list.pas.in > $@

clean:
	rm -fr *.o *.ppu listof*.pas asciibattle


