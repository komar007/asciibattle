all: main

%: %.pas physics.pas config.pas
	fpc $<

%.run: %
	./$<

%.rin: % %.in
	./$< <$<.in

