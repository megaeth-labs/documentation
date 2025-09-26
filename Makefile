# Documentation website build system
# Converts Markdown files to HTML using Pandoc

# =============================================================================
# VARIABLES
# =============================================================================

# Source files and directories
FILE_PAGES := $(wildcard docs/*.md)
DIR_PAGES := $(wildcard docs/*/)

# Output files
FILE_OUTPUTS := $(patsubst docs/%.md,public/%.html,$(FILE_PAGES))
DIR_OUTPUTS := $(patsubst docs/%/,public/%.html,$(DIR_PAGES))
OUTPUTS := $(FILE_OUTPUTS) $(DIR_OUTPUTS)

# Manifest files for navigation
MANIFESTS := $(patsubst public/%.html,manifest/%.txt,$(OUTPUTS))

# Pandoc options
PANDOC_OPTS := --toc --standalone --shift-heading-level-by=1
TEMPLATE := template/template.html
NAVBAR := manifest/navbar.html

# =============================================================================
# MAIN TARGETS
# =============================================================================

.PHONY: website clean

# Build the complete website
website: $(OUTPUTS) public/style.css

# =============================================================================
# HTML GENERATION RULES
# =============================================================================

# Convert individual Markdown files to HTML
public/%.html: docs/%.md $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) "$<" > $@

# Convert directory of Markdown files to HTML
public/%.html: docs/%/ $(wildcard docs/%/*.md) $(TEMPLATE) $(NAVBAR)
	@mkdir -p public
	pandoc $(PANDOC_OPTS) --template $(TEMPLATE) --include-before-body=$(NAVBAR) --file-scope docs/$*/*.md > $@

# =============================================================================
# STYLE SHEET
# =============================================================================

public/style.css: template/style.css
	@mkdir -p public
	cp template/style.css public/style.css

# =============================================================================
# NAVIGATION GENERATION
# =============================================================================

# Generate navigation bar from all manifest files
$(NAVBAR): $(MANIFESTS)
	@mkdir -p manifest
	echo '<nav class="main-nav"><ul>' > $@
	cat manifest/*.txt >> $@
	echo '</ul></nav>' >> $@

# Generate navigation item for individual Markdown files
manifest/%.txt: docs/%.md template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* "$<" > $@

# Generate navigation item for directory of Markdown files
manifest/%.txt: docs/%/ $(wildcard docs/%/*.md) template/navitem.txt
	@mkdir -p manifest
	pandoc --template=template/navitem.txt --metadata=filename:$* --file-scope docs/$*/*.md > $@

# =============================================================================
# CLEANUP
# =============================================================================

clean:
	rm -rf public manifest
