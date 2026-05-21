# raw/

Drop files here to ingest into the second brain.

**Supported formats:** `.md`, `.txt`, `.html`, `.pdf`, `.pptx`, `.docx`, images (`.png`, `.jpg`, `.gif`)

**To ingest a file:**
```bash
./tools/ingest.sh raw/your-file.pdf
```

Or tell Claude Code: `ingest raw/your-file.pdf`

**Rules:**
- Files in this directory are immutable originals — never edit them
- The wiki exists so you don't re-read these files during queries
- After ingestion, the original stays here; wiki/sources/ gets the summary
