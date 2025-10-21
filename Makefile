FILE_PAGES := $(wildcard docs/*.md)
DIR_PAGES := $(wildcard docs/*/)

FILE_OUTPUTS := $(patsubst docs/%.md,public/%.html,$(FILE_PAGES))
DIR_OUTPUTS := $(patsubst docs/%/,public/%.html,$(DIR_PAGES))
OUTPUTS := $(FILE_OUTPUTS) $(DIR_OUTPUTS)

MANIFESTS := $(patsubst public/%.html,manifest/%.txt,$(OUTPUTS))

PANDOC_OPTS := --toc --standalone --shift-heading-level-by=1 --mathml 
TEMPLATE := template/template.html
NAVBAR := manifest/navbar.html

.PHONY: website clean

website: $(OUTPUTS) public/style.css

public/%.html: docs/%.md $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) "$<" > $@

public/%.html: docs/%/ $(wildcard docs/%/*.md) $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) --file-scope docs/$*/*.md > $@

public/style.css: template/style.css
	@mkdir -p public
	cp template/style.css public/style.css

$(NAVBAR): $(MANIFESTS)
	@mkdir -p manifest
	echo '<nav class="main-nav"><ul>' > $@
	cat manifest/*.txt >> $@
	echo '</ul></nav>' >> $@

manifest/%.txt: docs/%.md template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* "$<" > $@

manifest/%.txt: docs/%/ $(wildcard docs/%/*.md) template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* --file-scope docs/$*/*.md > $@

clean:
	rm -rf public manifest
