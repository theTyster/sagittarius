# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handled this request**

This is advice with no change to make, so I answered directly. I did not run tools, start a knowledge base, or write checks. I assumed a single-user app on one machine, with no sync, no multi-user access, and no need to ship the data anywhere. If you plan to sync across devices or share recipes, the answer would change, so I flag that below.

**2. My answer**

I'd use **SQLite**, with one caveat about JSON.

SQLite fits a recipe app well. Recipes have structure: a title, an ingredient list with quantities and units, steps, tags, and maybe ratings or photos. SQLite stores that cleanly in related tables. It also gives you:

- **Search and filtering** without writing your own code. "Recipes with chicken, under 45 minutes, tagged 'weeknight'" is one query. With SQLite's FTS5 extension, you also get full-text search over titles and steps.
- **Safe writes.** If the app crashes while saving, a JSON file can be left half-written and corrupted. SQLite writes transactionally, so you keep the old data or the new data, not a mix.
- **Schema changes over time.** You will probably add fields later, such as "last cooked" or "source URL." Migrations are easier to manage in a database than by rewriting JSON files.
- **Zero setup.** It is a single file, and most languages ship with it. Python's `sqlite3` module is in the standard library.

Plain JSON is the better choice in one case: you want to read and hand-edit the files in a text editor, track every change in git, and keep the collection small (dozens to low hundreds of recipes) with no search needs. If that describes you, one JSON file per recipe is a reasonable choice. You lose atomic updates across files and querying, but git diffs and manual editing are easy to read.

My default is SQLite. Choose JSON only if git history and hand-editing matter more to you than querying and safe writes. If you expect to sync between devices or share recipes with others, tell me, because that moves the answer toward a more deliberate design, such as SQLite plus a sync layer, or a hosted backend.
