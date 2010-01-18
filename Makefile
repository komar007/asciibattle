TYPES=Rocket IntVector

all: asciibattle

asciibattle: asciibattle.pas crtinterface.pas game.pas battlefield.pas physics.pas types.pas config.pas staticconfig.pas lists.pas geometry.pas
	fpc -g -pg -Mobjfpc asciibattle.pas

lists.pas: list.pas.in listimpl.pas.in
	echo "unit Lists;" > lists.pas
	echo "interface" >> lists.pas
	echo "uses Types, Geometry;" >> lists.pas
	for f in $(TYPES); do \
		sed -e 's/_X_/'$$f'/g' list.pas.in >> lists.pas; \
	done
	echo "implementation" >> lists.pas
	for f in $(TYPES); do \
		sed -e 's/_X_/'$$f'/g' listimpl.pas.in >> lists.pas; \
	done
	echo "end." >> lists.pas

clean:
	rm -fr *.o *.ppu lists.pas early_demo iface_test


