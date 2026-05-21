# Ingestion Error Catalog

Each entry = one resolved error. Format: symptom, root cause, what was tried, what worked, and why it's the right fix.
New entries are appended after each confirmed fix (per Self-Learning Protocol in `ingest-source.md`).

---

## 2026-05-12 | PPTX files fail to extract text

**Symptom:**
Attempting to read `.pptx` files via the Read tool returns binary or nothing. Attempts to install `python-pptx` fail with various errors.

**Root cause:**
This Ubuntu system has no `pip`, no `pip3`, no `libreoffice`, and Python's `ensurepip` module is not installed (common on minimal Debian/Ubuntu setups). The system is marked `EXTERNALLY-MANAGED`, blocking system-wide pip installs. venv creation fails without `python3-venv`.

**What was tried (in order):**
1. Read tool on `.pptx` directly — binary, unreadable
2. `libreoffice --headless --convert-to txt` — `libreoffice` not installed (exit 127)
3. `pip install python-pptx` — `pip` not found
4. `pip3 install python-pptx` — `pip3` not found
5. `python3 -m pip install python-pptx` — `No module named pip`
6. `uv pip install python-pptx --system` — blocked by `EXTERNALLY-MANAGED`
7. `python3 -m venv /tmp/pptx-env` — failed, `ensurepip` not available
8. `apt-get install python3-pptx` — no sudo access

**What worked:**
PPTX (and DOCX) files are ZIP archives containing XML. `unzip` is always available. Text content lives in specific XML tags:
- PPTX: `<a:t>` tags in `ppt/slides/slide*.xml`
- DOCX: `<w:t>` tags in `word/document.xml`

```bash
unzip -q "file.pptx" -d /tmp/pptxdir
grep -oP '(?<=<a:t>)[^<]+' /tmp/pptxdir/ppt/slides/slide*.xml
```

**Canonical fix:**
`tools/extract-office.sh` — handles both PPTX and DOCX. Call via Bash tool:
```bash
./tools/extract-office.sh raw/MyFile.pptx
```

**Why this is the right fix:**
- Zero dependencies beyond `bash` + `unzip` (both guaranteed on Ubuntu)
- No network access, no pip, no venv
- Works for all well-formed Office XML files (Office 2007+)
- Handles both PPTX and DOCX with the same mechanism
- Reusable script so future sessions don't rediscover this

**Limitations:**
- Does not preserve slide order 100% reliably if filenames are not sequential (rare)
- Does not extract text from embedded images, charts, or SmartArt
- DOCX tables: text may run together without separators

---

## 2026-05-20 | DOCX extraction returns empty output

**Symptom:**
`tools/extract-office.sh` on a `.docx` file produces no output (exit 0, empty stdout), even though the file is valid.

**Root cause:**
The grep pattern `(?<=<w:t>)[^<]+` uses a fixed lookbehind that requires the tag to be exactly `<w:t>`. Modern DOCX files (Word 2010+) frequently emit `<w:t xml:space="preserve">` instead. The attribute causes the lookbehind to fail silently, yielding no matches.

**What worked:**
Replace the lookbehind with a pattern that skips attributes using `\K`:
```bash
grep -oP '<w:t[^>]*>\K[^<]+' word/document.xml
```

**Canonical fix:**
Already applied to `tools/extract-office.sh` (2026-05-20). No manual workaround needed going forward.

**Why this is the right fix:**
`\K` resets the match start after consuming `<w:t[^>]*>`, so only the text content is captured regardless of what attributes are present. Zero-cost change; no new dependencies.

---
