TYPES=Rocket IntVector

all: iface_test early_demo

early_demo: early_demo.pas battlefield.pas physics.pas types.pas config.pas staticconfig.pas lists.pas geometry.pas
	fpc -g -Mobjfpc early_demo.pas

iface_test: iface_test.pas crtinterface.pas
	fpc -g -Mobjfpc iface_test.pas

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
	rm -fr *.o *.ppu listof*.pas early_demo iface_test


