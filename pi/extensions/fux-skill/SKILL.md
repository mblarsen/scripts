---
name: fux
description: Fork the current session to explore a topic in isolation. Use only when the user requests it or explicitly agrees to fork.
---

# Fux

Fork the session to explore a topic without derailing the main conversation.

## When to Use

- User explicitly asks to fork or explore something separately
- User says "let's talk about X first" when multiple topics are pending
- User has follow-up questions on a tangential topic
- User wants to try an approach before committing to it in the main session

## When NOT to Use

- **As the default** for every decision or branching question
- To dodge temporary uncertainty — it's better to make a reasonable choice and use `/tree` to revisit if needed
- When the user hasn't asked to fork or explicitly agreed

## Asking to Fork

You can suggest forking using the `ask_user` tool when it makes sense, for example:

- The user presents 3 options and says "let's discuss option 1"
- The user has a follow-up question on a related but separate topic
- You want to explore a "what if" scenario before applying it

Example prompts to the user:
- "Want to fork off and explore this in more detail?"
- "Should we split off to discuss this separately?"

If the user agrees, run `/fux` or `/fux prompt [your intent]`.

## After Merging

When `/fux merge --yes` completes, the child session file is deleted and the fork pane closes. The parent session's JSON was edited externally.

**You must restart the parent pi session** to see the merged content:

```bash
pi --resume <parent-session-path>
# or
pi /path/to/parent-session.jsonl
```

You can find the parent session path in the merge summary output, or use `/sessions` to browse available sessions.

Don't leave the user hanging — tell them to restart before continuing work in the parent.

## CLI Usage

```
/fux                          Fork, create new tmux pane
/fux prompt [text]            Fork and start with initial prompt
/fux merge [--dry-run]        Show what would be merged
/fux merge --yes              Merge fork back into parent (deletes fork)
/fux merge --yes --keep       Merge but keep the fork
```

## /tree vs /fux

Both create branches, but with different intents:

| | `/tree` | `/fux` |
|---|---|---|
| Use when | Exploring past decision points, resuming an earlier branch | Diving into a new topic or tangent |
| Stays in | Current pane | New tmux pane |
| Merge back | Via tree navigation | Via `/fux merge` |
| Typical scope | Minor detours within the same task | Significant exploration or side discussions |

Often it's better to stay on the session and use `/tree` to go back to a summary point later. Use `/fux` when the exploration is large enough to warrant full separation.