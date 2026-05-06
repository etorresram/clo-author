#!/bin/bash
# =============================================================================
# Build a Word (.docx) version of main.tex
# =============================================================================
# Requires: pandoc (>=3.0), pdftoppm (poppler), bash
# Usage:    cd paper/word_export && bash build_word.sh
# Output:   paper/word_export/Torres_2026_IA_Latam_Peru.docx
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAPER_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$(mktemp -d /tmp/paper_word_XXXXXX)"

echo "[1/4] Preparing working copy at $WORK_DIR"
cp -r "$PAPER_DIR"/* "$WORK_DIR/"
cd "$WORK_DIR"

echo "[2/4] Converting figure PDFs to PNG (200 DPI)"
for pdf in $(find figures -name "*.pdf" -type f); do
  base="${pdf%.pdf}"
  pdftoppm -png -r 200 -singlefile "$pdf" "$base"
done

echo "[3/4] Rewriting includegraphics paths from .pdf to .png"
for f in main.tex sections/*.tex; do
  sed -i.bak 's|\.pdf}|\.png}|g' "$f"
done

echo "[4/4] Running pandoc"
pandoc main.tex \
  -o Torres_2026_IA_Latam_Peru.docx \
  --citeproc \
  --bibliography=Bibliography_base.bib \
  --number-sections

cp Torres_2026_IA_Latam_Peru.docx "$SCRIPT_DIR/"
echo "Done: $SCRIPT_DIR/Torres_2026_IA_Latam_Peru.docx"
echo "(Working dir $WORK_DIR is preserved for inspection; remove manually when done)"
