SRC=$(wildcard *.mkd)
PDF=$(addprefix pdfs/, $(SRC:.mkd=.pdf))
TEX=$(SRC:.mkd=.tex)

OPTIONS=-f markdown --toc --number-sections --smart
TEMPLATE=pandoc.latex 


ifneq "$(TEMPLATE)" ""
TEMPLATEARG=--template=$(TEMPLATE)
endif

all: $(PDF)
	
tex: $(TEX)

#--highlight-style=pygments (the default), kate, monochrome, espresso, haddock, and tango
#-V highlight-bg=true

pdfs/%.pdf: %.mkd Makefile $(TEMPLATE)
	@echo "$(dir $@) $< $^ $(PDF)"
	pandoc $(OPTIONS) --latex-engine=xelatex  --highlight-style=haddock $(TEMPLATEARG) \
-V lang=english -V fontsize=11pt -V documentclass=article -V bg-color=238,245,240 -o $@ $<

%.tex: %.mkd Makefile $(TEMPLATE)
	pandoc $(OPTIONS) --highlight-style=haddock $(TEMPLATEARG) \
-V lang=english  -V  fontsize=11pt -V documentclass=article -o $@ $(@:.tex=.mkd)

test: test.mkd Makefile $(TEMPLATE)
	pandoc $(OPTIONS) --latex-engine=xelatex --highlight-style=haddock $(TEMPLATEARG) \
-V lang=english -V fontsize=11pt -V documentclass=article -o $@.pdf $@.mkd


.PHONY: clean

clean:
	rm -f pdfs/*.pdf *~ *.tex *.log
