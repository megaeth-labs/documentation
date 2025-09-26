INPUTS := $(wildcard *.md)
OUTPUTS := $(patsubst %.md,public/%.html,$(INPUTS))

website: $(OUTPUTS) public/style.css

public/%.html: %.md template.html
	mkdir -p public
	pandoc --standalone --shift-heading-level-by=1 --template template.html "$<" > $@ 

public/style.css: style.css
	mkdir -p public
	cp style.css public/style.css

.PHONY: clean
clean:
	rm -rf public
