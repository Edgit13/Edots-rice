# Filter lists

The browser's filter engine is the Rust `adblock` engine used by Brave, not a substring matcher. It understands ABP/EasyList and uBlock-style network rules.

Place downloaded `.txt` lists in the runtime cache:
`~/.cache/edot-browser/filters/`

The included `default.txt` is a small bootstrap list. Use `scripts/update_filters.sh` to fetch the configured upstream lists.
