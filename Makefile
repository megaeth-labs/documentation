FILE_PAGES := $(wildcard docs/*.md)
DIR_PAGES := $(wildcard docs/*/)

FILE_OUTPUTS := $(patsubst docs/%.md,public/%.html,$(FILE_PAGES))
DIR_OUTPUTS := $(patsubst docs/%/,public/%.html,$(DIR_PAGES))

OUTPUTS := $(FILE_OUTPUTS) $(DIR_OUTPUTS)

website: $(OUTPUTS) public/style.css

public/%.html: docs/%.md template/template.html
	mkdir -p public
	pandoc --standalone --shift-heading-level-by=1 --template template/template.html "$<" > $@

public/%.html: docs/%/ $(wildcard docs/%/*.md) template/template.html
	mkdir -p public
	pandoc --standalone --shift-heading-level-by=1 --template template/template.html --file-scope docs/$*/*.md > $@

public/style.css: template/style.css
	mkdir -p public
	cp template/style.css public/style.css

.PHONY: clean
clean:
	rm -rf public
