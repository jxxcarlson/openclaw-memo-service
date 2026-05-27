
# A Voice-enabled memo service


This is a description of a simple memo system that we are implementing in openclaw. It is housed in the directory `.openclaw/workspace`. The relevant folders are `memos/` and `memos-archive/`. The folder "memos" holds active memo-files. That is to say, memo-files that have been created by the user but which have not yet been edited and approved. When a memo-file has been approved, it is moved to the memo-archive folder. 

Here is a listing of the memos folder as it existed when we created the service:

```
2026-05-26.md
audio-archive
audio-inbox
INDEX.md
MEMO-COMMANDS.md
transcribe.sh
VOICE-MEMOS.md
```

- The first entry, `2026-05-26.md` is the name of a memo file created on The given date.
- The files `audio-archive`, `audio-inbox`, and `VOICE-MEMOS.md`, and `transcribe.sh` Are used for processing audio input, e.g. from Telegram. 
- The file, `MEMO-COMMANDS.md` describes a future command-based memo system.   

Incoming memos are posted to the current day's memo file.  From From time to time the user will edit the memo files and approve them. Once they are approved they are moved to the memo-archive folder. Below is the format of a typical memo file.

When A user writes or dictates a memo. He may say "topic," followed by a description of what the topic is. This should be placed immediately after the date followed by a comma.  If the user does not say "topic", a default topic is entered, e.g. "Memo" or "Voice Memo". 

The user may also say "tag" followed by the name of a tag. This should be entered in the memo as tag: the actual content of the tag. For example if the user says "tag scripta", it should be entered as "tag:scripta" . 

## Typical memo file

```
# 2026-05-26

## 7:45, Harlem Chamber Music Society

Some ideas re purpose, activities:

- Foster social and professional connections among classical musicians and lovers of classical music living in Harlem.
- Share food, drink, conversation and good cheer.
- Play music. Work in progress (performance, composition). Not polished. We are among friends and just play.
- Informal improv. Yes! Bach did it, so can we!!
- Meetings: once a month, e.g. first Sunday afternoon or early evening of every month. We need to think about our algorithm. Nights where many of us are busy should be avoided.
- Other ideas!
- Names of people to contact for our first meeting
- Date for our first meeting

## 04:55 — To do by Thursday 5pm

- Think about Harlem chamber music society.
- Buy stuff for and prepare snacks for Lora.
- Think about piano lessons
- Call Moe's Books in Berkeley to see what's happened with my shipment.

## 05:01 — Voice Memo

Call Moe's Books in Berkeley to see what's happened with my shipment.
```
