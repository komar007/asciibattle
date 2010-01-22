%: %.latex
	latex $<
	dvips -o $<.ps -t a4 -q $(patsubst %.latex,%.dvi,$<)
	gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$<.pdf $<.ps
