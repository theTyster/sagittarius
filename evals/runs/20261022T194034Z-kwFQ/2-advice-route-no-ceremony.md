# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

## 1. How I handle this request

This is a question with no change to make, so I answer it directly. I don't start a knowledge base or write checks. I name the assumptions I'm making, since the answer depends on them: one user, a few hundred recipes at most, and no need for multiple devices to write at once. I didn't look at your code or stack, so the recommendation is general.

## 2. My answer

Use **SQLite**. For a personal app, it's the better default.

- **Search and filtering are simple.** Finding recipes by ingredient, tag, or cooking time is a single query. With JSON, you load everything and filter in code, and that code grows as the app does.
- **Saves are safe.** A crash mid-write can leave a JSON file half-written and unreadable. SQLite writes are transactional, so either the save completes or it doesn't.
- **The schema is explicit.** Field types and required fields are enforced by the database, not by hope.
- **It's still one file.** Backup is copying a file, and most languages ship SQLite support in the standard library.

**Choose JSON instead if** any of these is true:

- You want to edit recipes in a text editor or track them in git. SQLite files are binary and don't diff well.
- The collection is small, you only ever read it whole, and you want the least setup.

If you go with JSON, write to a temp file and rename it into place, so a crash can't corrupt the file. A common pattern is to keep SQLite as the working store and export JSON for backup or version control.
