# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handle this request**

This is a question with a choice between two options, and no change to make. I answer directly, lay out the trade-offs, state my assumptions, and say what I don't know. I didn't run any tools or touch any files.

**2. Answer**

Use SQLite. It's a better default for a recipe app, even one for a single person.

- **Search and filtering are easier.** Queries like "recipes with chickpeas under 30 minutes tagged vegetarian" are one line of SQL. With JSON, you write that logic yourself, or load everything into memory and loop over it.
- **Relationships stay consistent.** Ingredients, tags, and recipe steps are linked records. SQLite enforces foreign keys and handles partial writes, so a crash mid-save won't leave a half-written file.
- **Schema changes are simpler.** When you add a field later, a migration is a small, repeatable step. With JSON, old files can silently drift from new ones.
- **It is still one file.** SQLite is a single file with no server, so backup and copying work the same way they would for JSON.

JSON is the better choice in a few cases:

- You want to hand-edit recipes in a text editor.
- You want to track changes in git and read the diffs.
- You have a few dozen recipes and no plan to search or filter them.

A workable middle path is SQLite as the store with a JSON export command, or one JSON file per recipe if git history matters more to you than queries.

My assumptions: the app runs on one machine, you won't sync across devices or share with others, and the collection stays in the hundreds of recipes at most. If you'll want sync, multiple users, or a web front end later, SQLite is a stronger choice still.

I don't know what your app's core features are. If the main thing you'll do is browse recipes you've written by hand, JSON would serve you well. If you plan to search, scale, or grow the schema, go with SQLite.
