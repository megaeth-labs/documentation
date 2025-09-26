INPUTS := $(wildcard docs/*.md)
OUTPUTS := $(patsubst docs/%.md,public/%.html,$(INPUTS))

website: $(OUTPUTS) public/style.css

public/%.html: docs/%.md template/template.html
	mkdir -p public
	pandoc --standalone --shift-heading-level-by=1 --template template/template.html "$<" > $@ 

public/style.css: template/style.css
	mkdir -p public
	cp template/style.css public/style.css

.PHONY: clean
clean:
	rm -rf public
