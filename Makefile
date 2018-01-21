# Internal variables
_POST_DATE  ?= $(shell date +%Y-%m-%d)
_POST_TITLE ?= $(shell echo "$(TITLE)" | sed 's/'\''//g; s/ \+/_/g; s/.*/\L&/g')
_POST_PATH  ?= posts/$(_POST_DATE)-$(_POST_TITLE).md

.PHONY: new
new:
	[ -n "$(TITLE)" ]
	[ ! -f "$(_POST_PATH)" ]
	@printf "%s\n" \
	  "---" \
	  "title: \"$(TITLE)\"" \
	  "tags:" \
	  "---" "" > "$(_POST_PATH)"
	@echo CREATED: $(_POST_PATH)

.PHONY: watch
watch: build
	stack exec jdreaver-site -- clean
	stack exec jdreaver-site -- watch

.PHONY: build
build:
	stack build --pedantic

.PHONY: generate
generate: build
	stack exec jdreaver-site -- build

.PHONY: deploy
deploy: generate
	cd _site/ && aws s3 sync --delete . s3://jdreaver.com

.PHONY: check
check:
	stack install hlint weeder
	weeder .
	hlint hakyll.hs
