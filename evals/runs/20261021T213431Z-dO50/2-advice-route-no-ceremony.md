# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handle this request**

This is a question, not a change request, so I'm answering directly. I didn't open a knowledge base or run any tools, and I didn't touch any files. I assumed the app is single-user, runs on one machine, holds a few hundred to a few thousand recipes, and has no sync or multi-user needs. If any of those are wrong, the answer could change.

**2. Answer**

I'd use **SQLite**, stored as one file.

SQLite is still a single file, so it's about as simple to back up as JSON. It also gives you three things that JSON files make awkward:

- **Searching and filtering.** Finding recipes by ingredient, tag, or cooking time is a query. With JSON you load everything and filter it in code, which is fine at small scale but gets clumsy as you add fields.
- **Relationships.** Ingredients, tags, meal plans, and "recipes I cooked on this date" are naturally separate tables. Forcing them into JSON means nested structures you have to keep consistent by hand.
- **Safe writes.** If the app crashes halfway through saving, a JSON file can be left corrupted. SQLite writes transactionally, so you won't lose a recipe to a half-written file.

JSON would be the better choice if you want to hand-edit recipes in a text editor, diff them in git, or keep the app very simple with no schema changes. One file per recipe is a reasonable middle ground if you go that way.

Whichever you pick, keep an export path (a JSON dump from SQLite, or the JSON files themselves) so your data stays readable outside the app.
