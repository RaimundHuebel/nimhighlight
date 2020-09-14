###
# Makefile for highlighter project.
# @author Raimund Hübel <raimund.huebel@googlemail.com>
###

.PHONY: default
default: build


.PHONY: build
build: dist


.PHONY: dist
dist: dist/release dist/debug dist/doc


.PHONY: dist/release
dist/release:
	mkdir -p dist/release
	#nimble build -o:dist/release/highlight -d:release --opt:size highlight
	nim compile -o:dist/release/highlight -d:release --opt:size src/highlight.nim
	-strip --strip-all dist/release/highlight
	-upx --best dist/release/highlight


.PHONY: dist/debug
dist/debug:
	mkdir -p dist/debug
	#nimble build -o:dist/debug/highlight -d:allow_debug_mode highlight
	nim compile -o:dist/debug/highlight -d:allow_debug_mode src/highlight.nim


.PHONY: dist/doc
dist/doc:
	# see: https://nim-lang.org/docs/docgen.html
	mkdir -p dist/doc
	cd dist/doc && nim doc --project --index:on ../../src/highlight.nim


.PHONY: test
test:
	nimble test



.PHONY: clean
clean:
	rm -rf dist highlight

.PHONY: mrproper
mrproper: clean


.PHONY: distclean
distclean:
	git clean -fdx .
