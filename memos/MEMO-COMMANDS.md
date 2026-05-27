# Memo Commands

Simple text-based commands to control your memo system via Telegram.

## Commands

### `/memo [text]`
Add a timestamped entry to today's memo file.
- Automatically includes current topic (if set) and tags
- Creates a new section if topic changes

**Example:**
```
/memo This is a quick note about the project
```

### `/topic [name]`
Set the topic for subsequent memos. Creates a new section.

**Example:**
```
/topic Project Planning
```

All memos after this will be grouped under "Project Planning" until you change the topic.

### `/tag [tag1] [tag2] [...]`
Add tags to the next memo entry (or update current tags).

**Example:**
```
/tag #scripta #elm #workflow
```

### `/review`
Mark today's memo file as reviewed and move it to the archive.
- File moves to: `memos-archive/2026/05/2026-05-26.md`
- Monthly index is updated
- Tomorrow's file is created automatically

### `/clear-topic`
Clear the current topic (entries return to no section).

### `/clear-tags`
Clear all current tags.

---

## Workflow Example

```
/topic Morning Thoughts
/tag #brainstorm

/memo Just woke up, can't sleep, trying to get work done

/tag #openclaw
/memo Setting up the memo service workflow

/topic Scripta Work
/tag #scripta #elm

/memo Need to refactor the parser

/review
```

Result: Today's file is archived with entries grouped by topic, properly tagged.

---

**Note:** Commands are case-insensitive. Just type naturally.
