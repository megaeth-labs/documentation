INPUTS := $(wildcard *.md)
OUTPUTS := $(patsubst %.md,public/%.html,$(INPUTS))

website: $(OUTPUTS) public/neat.css

public/%.html: %.md template.html
	mkdir -p public
	pandoc --standalone --shift-heading-level-by=1 --template template.html "$<" > $@ 

public/neat.css: neat.css
	mkdir -p public
	cp neat.css public/neat.css

.PHONY: clean
clean:
	rm -rf public
