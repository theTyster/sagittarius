# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handle this request**

This is a choice between two options with no change to make, so I answer directly without a knowledge base, checks, or tools. I assume a single user, a few hundred recipes at most, and no sync across devices. If any of that is wrong, the answer could change.

**2. The answer**

Use SQLite. For a personal recipe app it is the better default, for three reasons:

- **Recipes are relational.** A recipe has many ingredients, tags, and steps. SQLite handles those with tables and foreign keys. With JSON you end up nesting everything in one file or writing your own index.
- **Searching is easier.** Questions like "every recipe with chickpeas and no oven" are one SQL query. With JSON you load everything and filter in code, and that code grows as the app does.
- **Writes are safer.** A crash during a JSON save can corrupt the whole file. SQLite writes are transactional, so a crash leaves the database intact.

SQLite is also one file, needs no server, and both Python and Node read and write it from the standard library or a small driver. Back it up by copying the file, or use `sqlite3 recipes.db .dump > backup.sql` for a text copy that git can track.

JSON files would be the better choice if you have only a few dozen recipes, you edit them by hand in a text editor often, or you want readable git diffs of every change. Even then, you could keep a JSON export as a backup alongside the database.
