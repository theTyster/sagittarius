# 2 advice-route-no-ceremony (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

I'm writing a small personal recipe app that only I will use. Should I store the data in SQLite or in plain JSON files?

1. How do you handle this request?
2. Give me your answer.

## Answer

**1. How I handled this request**

This is a question that asks for advice, not a change to make. I answered directly, without running tools, reading files, or starting a knowledge base. I assumed a single user, one app process, no sync, and mostly text recipes. I did not check your project or your stack, so the answer rests on those assumptions.

**2. Answer**

I would use SQLite. It costs little extra for a personal app, and it avoids problems that plain JSON files can cause as the app grows.

Plain JSON is the better choice in one case: you have a few dozen recipes, the app only displays them, and you want to edit them by hand or track them in git. Files are easy to read and diff, and they need no schema or driver.

SQLite pays off once you need any of these:

- **Search or filtering** by ingredient, tag, or cook time without loading everything into memory.
- **Relationships**, such as ingredients shared across recipes, a shopping list built from several recipes, or meal plans.
- **Safe saves.** Each save writes one row in a transaction. With JSON, every save rewrites a whole file, and a crash during the write can corrupt it. You would have to write to a temporary file and rename it to avoid that.

Two things would change my answer. If you expect to edit recipes by hand in a text editor often, JSON wins. If you expect to share or sync data across devices, you need a sync design either way, and SQLite does not solve that by itself.

The unknowns that matter most are how many recipes you expect, whether you need search, and what language or framework the app uses. Each of these could move the answer, though SQLite is a safe default in most cases.
