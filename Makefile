# Makefile for EDGE's User Guide

SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = EDGEsUserGuide
SOURCEDIR     = docs
BUILDDIR      = build

help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
