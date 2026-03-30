FILE_PAGES := $(wildcard docs-legacy/*.md)
DIR_PAGES := $(wildcard docs-legacy/*/)

FILE_OUTPUTS := $(patsubst docs-legacy/%.md,public/%.html,$(FILE_PAGES))
DIR_OUTPUTS := $(patsubst docs-legacy/%/,public/%.html,$(DIR_PAGES))
OUTPUTS := $(FILE_OUTPUTS) $(DIR_OUTPUTS)

MANIFESTS := $(patsubst public/%.html,manifest/%.txt,$(OUTPUTS))

PANDOC_OPTS := --toc --standalone --shift-heading-level-by=1
TEMPLATE := template/template.html
NAVBAR := manifest/navbar.html

.PHONY: website clean

website: $(OUTPUTS) public/style.css

public/%.html: docs-legacy/%.md $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) "$<" > $@

public/%.html: docs-legacy/%/ $(wildcard docs-legacy/%/*.md) $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) --file-scope docs-legacy/$*/*.md > $@

public/style.css: template/style.css
	@mkdir -p public
	cp template/style.css public/style.css

$(NAVBAR): $(MANIFESTS)
	@mkdir -p manifest
	echo '<nav class="main-nav"><ul>' > $@
	cat manifest/*.txt | sort -k1 -n | cut -f2 >> $@
	echo '</ul></nav>' >> $@

manifest/%.txt: docs-legacy/%.md template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* "$<" > $@

manifest/%.txt: docs-legacy/%/ $(wildcard docs-legacy/%/*.md) template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* --file-scope docs-legacy/$*/*.md > $@

clean:
	rm -rf public manifest
