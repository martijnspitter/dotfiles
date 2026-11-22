import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

/**
 * Guard that blocks destructive shell commands before the bash tool runs them.
 *
 * Each rule is a regex tested against the raw command string plus a short
 * reason. Matching a rule hard-blocks the tool call (no confirm prompt) — the
 * model sees the reason and must choose a safer path or ask the user to run it
 * manually. Tuned to catch history/remote-rewriting git ops and irreversible
 * filesystem/data commands while leaving ordinary work untouched.
 */
const RULES: Array<{ pattern: RegExp; reason: string }> = [
  // --- git: history / remote rewriting ---
  {
    pattern: /\bgit\s+push\b[^\n]*(--force(?!-with-lease)\b|(?:^|\s)-f\b)/,
    reason: "git push --force / -f rewrites remote history. Use --force-with-lease, or run it yourself.",
  },
  {
    pattern: /\bgit\s+reset\b[^\n]*--hard\b/,
    reason: "git reset --hard discards uncommitted work. Confirm intent and run it manually.",
  },
  {
    pattern: /\bgit\s+clean\b[^\n]*-[a-z]*f/,
    reason: "git clean -f permanently deletes untracked files. Run it yourself after checking `git clean -n`.",
  },
  {
    pattern: /\bgit\s+branch\b[^\n]*-D\b/,
    reason: "git branch -D force-deletes an unmerged branch. Confirm and run it manually.",
  },
  {
    pattern: /\bgit\s+push\b[^\n]*--delete\b|\bgit\s+push\b[^\n]*\s:\S/,
    reason: "Deleting a remote branch is destructive. Run it yourself.",
  },
  {
    pattern: /\bgit\s+(checkout|restore|switch)\b[^\n]*(--force|\s-f\b)/,
    reason: "Forced checkout/restore discards local changes. Confirm and run it manually.",
  },
  {
    pattern: /\bgit\s+(rebase|filter-branch|filter-repo)\b/,
    reason: "History-rewriting git op. Run it yourself so you can supervise it.",
  },
  {
    pattern: /\bgit\s+update-ref\s+-d\b|\bgit\s+reflog\b[^\n]*\b(delete|expire)\b/,
    reason: "Editing refs/reflog is destructive and hard to undo. Run it manually.",
  },

  // --- filesystem / data destruction ---
  {
    pattern: /\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b/,
    reason: "rm -rf is irreversible. Confirm the path and run it yourself.",
  },
  {
    pattern: /\brm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(\/|~|\*|\.)/,
    reason: "Forced rm at a root/home/glob target is dangerous. Run it manually.",
  },
  {
    pattern: /\b(mkfs\.\w+|mkfs)\b|\bdd\s+[^\n]*\bof=\/dev\//,
    reason: "Disk-format / raw-write command. Never run automatically.",
  },
  {
    pattern: />\s*\/dev\/(sd[a-z]|nvme\d|disk\d)/,
    reason: "Redirect into a raw block device destroys the disk. Run it yourself.",
  },
  {
    pattern: /\bchmod\s+-R\s+0*7*[0-7]{3}\s+\/(?:\s|$)/,
    reason: "Recursive chmod at filesystem root is destructive. Run it manually.",
  },
  {
    pattern: /\b(shutdown|reboot|halt|poweroff)\b/,
    reason: "System power command. Run it yourself if you really mean it.",
  },
  {
    pattern: /:\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;/,
    reason: "Fork bomb pattern. Blocked.",
  },

  // --- package / db drops ---
  {
    pattern: /\bDROP\s+(DATABASE|TABLE|SCHEMA)\b/i,
    reason: "Destructive SQL DDL. Run it yourself against the right environment.",
  },
];

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command ?? "";
    for (const { pattern, reason } of RULES) {
      if (pattern.test(command)) {
        return { block: true, reason: `Blocked destructive command: ${reason}` };
      }
    }
  });
}
