###
# Makefile for highlighter project.
# @author Raimund Hübel <raimund.huebel@googlemail.com>
###

.PHONY: default
default: build


.PHONY: build
build: build/release


.PHONY: build/release
build/release:
	nimble build -d:release --opt:size highlight
	-ls -l highlight
	-strip --strip-all highlight
	-upx --best highlight
	-ls -l highlight


.PHONY: build/debug
build/debug:
	nimble build highlight


.PHONY: test
test:
	nimble test


.PHONY: clean
clean:
	$(RM) highlight

.PHONY: mrproper
mrproper: clean


.PHONY: distclean
distclean:
	git clean -fdx .
