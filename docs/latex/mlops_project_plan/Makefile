# Makefile for LaTeX document compilation

# Define the main target
PROJECT = main

# Default rule
all: $(PROJECT).pdf

# Rule to build the PDF
# We run pdflatex twice to ensure all references and formatting are resolved correctly.
$(PROJECT).pdf: $(PROJECT).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(PROJECT).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(PROJECT).tex

# Clean rule to remove temporary and auxiliary files generated during compilation
clean:
	rm -f *.aux *.log *.out *.toc *.nav *.snm *.vrb *.pdf

.PHONY: all clean
