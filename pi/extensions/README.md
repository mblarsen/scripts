# Pi Extensions

Custom extensions for [pi](https://github.com/earendil-works/pi-coding-agent).

## Install

Add the extensions to your pi settings (`~/.pi/agent/settings.json`) under `packages`:

```json
{
  "packages": [
    {
      "source": "git:github.com/mblarsen/scripts",
      "extensions": [
        "pi/extensions/continue-from.ts",
        "pi/extensions/fux.ts",
        "pi/extensions/footer-manager.ts"
      ]
    }
  ]
}
```

## Extensions

### continue-from

Resume or nudge a conversation that has paused or stalled.

Provides the `/continue-from` and `/nudge` slash commands, plus an **Alt+C** keybinding in the input editor.

**Use cases:**
- The agent stopped mid-task — continue from where it left off.
- Rewind to a prior user message and re-send it.
- Send a hidden "continue" nudge without modifying session history.

**Commands:**
| Command | Description |
|---|---|
| `/continue-from` | Interactive picker: nudge-only, agent, or user |
| `/continue-from nudge-only` | Send a hidden continue message (no rewind) |
| `/continue-from agent` | Rewind to the last assistant message and continue |
| `/continue-from user` | Rewind to the last user message |
| `/nudge` | Alias for `/continue-from nudge-only` |
| **Alt+C** | Quick shortcut for `/continue-from` |

---

### fux

Fork a pi session into a side pane for tangential exploration, then merge changes back.

Provides the `/fux` slash command and the `fux_fork` LLM tool (merge and delete remain slash-command-only for safety).

**Use cases:**
- Try an experimental approach without polluting the main session.
- Explore a side topic while keeping the main conversation clean.
- Parallelise work across multiple tmux panes.

**Commands:**
| Command | Description |
|---|---|
| `/fux` | Fork current session into a new tmux pane |
| `/fux prompt <text>` | Fork with an initial prompt sent to the child |
| `/fux merge [--dry-run] [--yes] [--keep\|--delete]` | Merge child fork back into parent |
| `/fux delete [--yes]` | Delete the child fork and close the pane |
| `/fux toggle` | Show or hide the fux guidance widget |

**LLM tool:** `fux_fork` — available to the agent to fork sessions programmatically.

After merging, restart the parent session:

```
pi --resume <parent-session-file>
```

---

### footer-manager

Manage the pi status footer — toggle built-in items, reorder extension statuses, and enter a minimal "zen" mode.

**Use cases:**
- Hide the model name, working directory, or token stats.
- Reorder or toggle extension-provided status items.
- Enter zen mode to minimise footer noise during focus work.

**Commands:**
| Command | Description |
|---|---|
| `/footer-manager` | Open the interactive footer manager |
| `/footer-manager on` | Enable the managed footer |
| `/footer-manager off` | Disable the managed footer (revert to default) |
| `/footer-manager reset` | Reset layout to defaults |
| `/footer-manager zen` | Toggle zen mode (hide all items) |
| `/footer-manager zen on` | Enable zen mode |
| `/footer-manager zen off` | Disable zen mode |
| `/footer-manager ext <key>` | Toggle visibility of a specific footer item |
| `/footer-manager status-line on` | Show the extension status line |
| `/footer-manager status-line off` | Hide the extension status line |

**Interactive controls** (inside the manager overlay):
- **↑↓** select item · **Space/Enter** toggle visibility · **u/d** reorder extension items · **r** reset · **Esc** close
