########################################################################
## Makefile to generate multiple document from the same markdown file
## using  pandoc software:
##
## References:
##
## Authors: 
##	- Benoit Rat (Seven Solutions, www.sevensols.com)
##
## GNU Lesser General Public License Usage
## This file may be used under the terms of the GNU Lesser
## General Public License version 2.1 as published by the Free Software
## Foundation and appearing in the file LICENSE.LGPL included in the
## packaging of this file.  Please review the following information to
## ensure the GNU Lesser General Public License version 2.1 requirements
## will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
########################################################################


## Obtaining the proper file
SRC=$(wildcard *.md)
PDF=$(addprefix pdf/, $(SRC:.md=.pdf))
TEX=$(SRC:.md=.tex)

## Pandoc arguments
OPTIONS=-f markdown --toc --number-sections --smart --reference-links
TEMPLATE=pandoc.latex 


ifneq "$(TEMPLATE)" ""
TEMPLATEARG=--template=$(TEMPLATE)
endif

#--highlight-style=pygments (the default), kate, monochrome, espresso, haddock, and tango
#-V highlight-bg=true

## Main targets
all: $(PDF)
tex: $(TEX)
pdf: $(PDF)

## Special targets to create directory	
DIR_%:
	mkdir -p $(subst DIR_,,$@)	

pdf/%.pdf: %.md Makefile $(TEMPLATE) DIR_pdf
	pandoc $(OPTIONS) --latex-engine=xelatex  --highlight-style=haddock $(TEMPLATEARG) \
-V lang=english -V fontsize=11pt -V documentclass=article -V bg-color=238,245,240 -o $@ $<

%.tex: %.md Makefile $(TEMPLATE) 
	@echo "$(dir $@) $< $^ $(TEX)"
	pandoc $(OPTIONS) --highlight-style=haddock $(TEMPLATEARG) \
-V lang=english  -V  fontsize=11pt -V documentclass=article -o $@ $<

.PHONY: clean

clean:
	rm -f pdf/*.pdf *~ *.tex *.log

	
	
