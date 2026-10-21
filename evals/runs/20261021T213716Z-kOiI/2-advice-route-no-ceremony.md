# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handle this request**

This is a question that asks for advice, not a change to the code or files. I answer directly, with no knowledge base, checks, or tools, as you asked. I state my assumptions and what I don't know. I don't need to ask first, because the answer holds across most stacks. It would change only if you have a constraint I can't see, such as a language or platform that makes one option awkward.

**2. My answer**

Use **SQLite**. It is a good default even for a single-user app, for these reasons:

- **Safe writes.** A crash or a power cut in the middle of saving a JSON file can leave it truncated or corrupt. SQLite writes are transactional, so a save either completes or doesn't happen.
- **Easy queries.** Searching by ingredient, tag, or cooking time is a single SQL statement. With JSON, you load everything and filter it in code, and that code grows as the app does.
- **Schema changes.** When you add a field, a migration handles existing rows. With JSON, you write a loader that copes with every older shape of the file.
- **Simple backup.** The whole database is one file, so copying it is a complete backup.
- **No extra dependency.** Python, Node, Go, and most other languages have SQLite support in the standard library or in a well-known package.

JSON is the better choice in a few cases:

- You have a few dozen recipes and never search across them.
- You want to edit recipes by hand in a text editor.
- You want a version history. Keeping one JSON file per recipe in a git repository gives you that for free, and it is a fine design for a personal app.

If you choose SQLite, keep photos and other large files on disk and store only their paths in the database. If you want both the history and the query support, a reasonable compromise is SQLite for the app with periodic JSON exports, or the reverse.

What would change my advice: if you tell me your language and whether you want to edit recipes by hand or track their history in git, I can recommend a specific setup.
