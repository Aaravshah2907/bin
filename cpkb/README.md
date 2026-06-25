# Competitive Programming Knowledge Base (CPKB)

CPKB is a local, terminal-first knowledge base designed to store, search, and track usages of competitive programming snippets, algorithms, and tricks. It uses SQLite for storage and has zero external dependencies, making it extremely fast, portable, and easy to maintain.

## Features

- **Store snippets**: Add code snippets with metadata like title, use case, and tags.
- **Search snippets**: Full-text search across titles, descriptions, tags, and code.
- **Track usage**: Record every time you use a snippet in a problem, linking to the file and optionally taking notes.
- **Terminal-first workflow**: Follows a standard Unix utility UX. No complex menus or web UIs.
- **Long-term persistence**: Built with standard libraries and a durable SQLite database schema meant to last for years.
- **XDG Base Directory compliant**: Stores data in `~/.local/share/cpkb`.

## Installation

You can install CPKB by copying the executable script to a directory in your PATH (e.g., `~/.local/bin/`).

```bash
mkdir -p ~/.local/bin
cp cpkb.py ~/.local/bin/cpkb
chmod +x ~/.local/bin/cpkb
```

Ensure `~/.local/bin` is in your `$PATH`.

## Usage

Here are the commands available in Version 1.2:

- `cpkb add`: Add a new snippet interactively.
- `cpkb list`: List all snippets.
- `cpkb show <id>`: Show details and code of a specific snippet (e.g., `CP0001`).
- `cpkb search <query>`: Search for snippets matching multiple words (AND search).
- `cpkb use <id> <file>`: Record the usage of a snippet in a specific file.
- `cpkb usages <id>`: List all recorded usages for a snippet.
- `cpkb stats`: Show basic database statistics, including unique tags count.
- `cpkb random`: Show a random snippet for review or practice.
- `cpkb edit <id>`: Edit a snippet's metadata and code in your default `$EDITOR`.
- `cpkb delete <id>`: Delete a snippet permanently.
- `cpkb recent`: Show the 10 most recently added snippets.
- `cpkb export`: Export your entire knowledge base to a single Markdown file.
- `cpkb backup`: Manually trigger a backup of the SQLite database.

### Example Workflow

1. Add a snippet:
   ```bash
   $ cpkb add
   Title: Fast Modular Exponentiation
   Description: O(log N) modular exponentiation
   Use case: Math problems
   Tags: math, modexp
   Enter the code (Ctrl+D on an empty line to finish):
   def power(base, exp, mod):
       res = 1
       base = base % mod
       while exp > 0:
           if exp % 2 == 1:
               res = (res * base) % mod
           exp = exp >> 1
           base = (base * base) % mod
       return res
   ^D
   ```

2. Search for the snippet later:
   ```bash
   $ cpkb search modexp
   ```

3. View it:
   ```bash
   $ cpkb show CP0001
   ```

4. Record that you used it to solve a problem:
   ```bash
   $ cpkb use CP0001 main.py
   Problem name (optional): CSES Exponentiation
   Notes (optional): Worked perfectly
   ```

## Directory Structure

The application will automatically create the required directories on first run:

```
~/.local/share/cpkb/
├── snippets.db
├── attachments/
├── backups/
├── exports/
├── imports/
└── logs/
```

## Requirements

- Python 3.11+
- No external dependencies

## License

Personal Knowledge Base (MIT License if shared).
