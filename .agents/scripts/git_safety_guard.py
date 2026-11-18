#!/usr/bin/env python3
"""
Cadence Git Safety Guard
PreToolUse hook script for run_command.
Intercepts shell execution to block destructive Git operations, automatic commits/pushes,
and unauthorized access to external sibling directories (e.g. Rivet).
"""

import sys
import json
import re
import shlex
from datetime import datetime, timezone
from pathlib import Path

# Destructive or prohibited operation patterns
PROHIBITED_PATTERNS = [
    # Automatic commits, pushes, and releases
    (r"\bgit\s+commit\b", "Automatic git commits are prohibited; developer retains commit custody"),
    (r"\bgit\s+push\b", "Automatic git pushes are prohibited"),
    (r"\bgit\s+tag\b", "Automatic tag creation/manipulation is prohibited"),
    
    # Destructive reset and clean operations
    (r"\bgit\s+reset\s+.*--hard\b", "Destructive git reset --hard is prohibited"),
    (r"\bgit\s+reset\s+--hard\b", "Destructive git reset --hard is prohibited"),
    (r"\bgit\s+clean\b", "Destructive git clean operations are prohibited"),
    (r"\bgit\s+restore\s+.*(\.|\-\-staged\s+\.)", "Destructive git restore . is prohibited"),
    (r"\bgit\s+checkout\s+(--\s+)?\.", "Destructive git checkout . is prohibited"),
    
    # Branch deletion and rebase
    (r"\bgit\s+branch\s+.*-[dD]\b", "Git branch deletion is prohibited"),
    (r"\bgit\s+rebase\b", "Git rebase is prohibited"),
    
    # Stash destruction
    (r"\bgit\s+stash\s+(drop|clear)\b", "Destructive git stash operations are prohibited"),
    
    # Force push variants
    (r"\bgit\s+.*--force\b", "Force operations are prohibited"),
    
    # Rivet isolation
    (r"\b(rivet|\.\./rivet|/Users/edwin/Dev/projects/rivet)\b", "Access or operations targeting the Rivet project are strictly prohibited"),
]

def log_audit(decision: str, command: str, reason: str = ""):
    """Lightweight audit logging to .agents/logs/git-safety.log"""
    try:
        log_dir = Path(__file__).resolve().parent.parent / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / "git-safety.log"
        now = datetime.now(timezone.utc).isoformat()
        entry = f"[{now}] [{decision.upper()}] Command: {command!r}"
        if reason:
            entry += f" | Reason: {reason}"
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(entry + "\n")
    except Exception:
        # Logging failure must never block normal tool execution
        pass

def inspect_command(cmd: str) -> tuple[bool, str]:
    """
    Evaluates whether a command contains prohibited or destructive actions.
    Returns (is_allowed, reason).
    """
    if not cmd or not cmd.strip():
        return True, ""
    
    cmd_stripped = cmd.strip()
    
    # Check regex patterns
    for pattern, explanation in PROHIBITED_PATTERNS:
        if re.search(pattern, cmd_stripped, re.IGNORECASE):
            return False, explanation
            
    return True, ""

def main():
    try:
        raw_input = sys.stdin.read()
        if not raw_input.strip():
            # Empty input - pass through
            print(json.dumps({"decision": "allow"}))
            return
            
        try:
            data = json.loads(raw_input)
        except json.JSONDecodeError as err:
            # Handle malformed JSON safely without crashing
            log_audit("error", "MALFORMED_INPUT", f"JSON decode error: {err}")
            print(json.dumps({
                "decision": "allow",
                "reason": "Cadence Git Safety Guard received non-JSON input; passing through safely."
            }))
            return

        tool_call = data.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})
        command_line = args.get("CommandLine", "")

        # Only evaluate run_command calls with a command line
        if tool_name != "run_command" or not command_line:
            print(json.dumps({"decision": "allow"}))
            return

        is_allowed, reason = inspect_command(command_line)
        
        if not is_allowed:
            diagnostic = (
                f"Blocked by Cadence Git Safety Guard: {reason}. "
                f"Prohibited command: '{command_line}'. "
                "Automatic execution rejected to preserve repository safety."
            )
            log_audit("deny", command_line, reason)
            print(json.dumps({
                "decision": "deny",
                "reason": diagnostic
            }))
            return

        # Allowed command
        log_audit("allow", command_line)
        print(json.dumps({"decision": "allow"}))

    except Exception as exc:
        # Failsafe: catch any unexpected exception and permit pass-through rather than breaking agent loop
        try:
            log_audit("error", "EXCEPTION", str(exc))
        except Exception:
            pass
        print(json.dumps({
            "decision": "allow",
            "reason": f"Cadence Git Safety Guard encountered internal exception: {exc}"
        }))

if __name__ == "__main__":
    main()
