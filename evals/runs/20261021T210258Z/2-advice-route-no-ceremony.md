# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handle this request**

This is a question that asks for advice, so I answer it directly. I don't start a knowledge base or run checks, and I don't change any files. My assumptions are one user, a few hundred recipes at most, and no need for a server or multi-device sync. If any of those are wrong, the answer could change.

**2. My answer: use SQLite.**

For a personal recipe app, SQLite is the better default, for these reasons:

- **Search and filtering are cheap.** Finding recipes by ingredient, tag, cuisine, or name is one query. With JSON, you load everything and filter in code, and that code grows with every new filter.
- **Writes are safe.** A crash or power loss during a JSON save can leave a half-written file and lose data. SQLite transactions avoid that.
- **The schema is explicit.** Recipes, ingredients, and tags can have typed columns and relations, so bad data fails early instead of showing up as a missing key months later.
- **It costs little.** It's a single file, and Python, Node, and most other languages ship with SQLite support. Backup is copying one file.

JSON is the better choice in a few cases:

- You want to hand-edit recipes in a text editor, or diff them in git.
- You have a few dozen recipes, you only ever open one at a time, and you'll never search.
- You want the data to be readable by other tools without installing anything.

If you do go with JSON, use one file per recipe, not one big file, and write each save to a temp file and rename it into place so a crash can't corrupt the original.
