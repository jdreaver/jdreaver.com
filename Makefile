site:
	ghc --make site.hs

publish: site
	./site rebuild

.PHONY: site publish
