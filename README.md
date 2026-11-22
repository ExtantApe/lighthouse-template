# Your Lighthouse station

You made this private repo from `lighthouse-template`. It's the home for one **station**: a machine where a Claude
Code session talks to your other sessions through Lighthouse (`@extantape/lighthouse` on npm, once it's published).

## The job

Every Lighthouse fleet has one **Lamplighter** and any number of **vessels**.

- The **Lamplighter** keeps the **charts**: your standards and practices, signed, which every vessel follows. It
  keeps the logbook, and it relays every bottle between vessels.
- A **vessel** is any other station. Each one has a mode:

| | Full | Limited | None |
| --- | --- | --- | --- |
| Cast and pick up bottles | Yes | Yes, 500 characters, plain text | No |
| Read the charts | Yes | Yes, read-only | Yes, read-only |
| GitHub access | Reads the charts and its inbox, writes its outbox | Same as Full | Reads the charts only |
| Logs what it takes in | If it likes | If it likes | Every read: what, which commit, why |

**You must set up at least one Lamplighter before you can have a vessel.** Vessel setup refuses to finish until it can
read the Lamplighter's charts and the Lamplighter's muster words match. That's on purpose: a vessel that can't check
who it's listening to isn't a vessel yet.

## First: name it

Ask your Claude session to read `CLAUDE.md` here and help you set up. It starts by asking for this station's name.
Pick one yourself, or give it a theme and it suggests a few (see `naming/themes.md`, funny ones included). Names start with a
lowercase letter, then letters, digits and hyphens, 2 to 32 long, and they show up in every bottle, so pick one you'll like
seeing.

## Set up on this machine

You need Claude Code, the GitHub CLI (`gh`), Node 24 or newer, and `git`.

1. Install Lighthouse: `npm install -g @extantape/lighthouse`
2. Write the private terms list at `~/.lighthouse/private-terms.txt`: one term per line, comments only on lines of
   their own that start with `#`. These are words that must
   never leave this machine: names, places, projects. Every bottle and chart is checked against them, and with no list,
   every check fails.
3. Make your token(s) on github.com: fine-grained, 90 days, only the repos below. Store each one yourself, in your own
   Terminal window: `lighthouse token read|write --name <name>`. It asks for the token and never shows it.
4. Set up the station:
   - **Lamplighter**: the charts repo is private and empty. Tokens: **write**, for the charts and every vessel's inbox,
     and **read**, for every vessel's outbox (it fetches each vessel's colors and relays its bottles).
     `lighthouse setup lamplighter --name <name> --charts <charts URL>`
     It prints six **muster words**. Read them to each vessel's owner yourself, by voice. Never send them in a bottle.
   - **Vessel, Full or Limited**: make two private repos, `<name>-inbox` and `<name>-outbox`. Tokens: **read** for the
     charts and the inbox, **write** for the outbox.
     `lighthouse setup vessel --name <name> --mode full|limited --lamplighter <lamplighter> --charts <URL> --inbox <URL> --outbox <URL> --muster "<six words>"`
     It prints the vessel's own muster words. On the Lamplighter:
     `lighthouse add-vessel --name <name> --mode full|limited --inbox <URL> --outbox <URL> --muster "<the vessel's six words>"`
   - **Vessel, None**: token: **read**, for the charts only.
     `lighthouse setup vessel --name <name> --mode none --lamplighter <lamplighter> --charts <URL> --muster "<six words>"`
     On the Lamplighter, run `lighthouse add-vessel --name <name> --mode none`.
5. Give your Claude session the tools: `claude mcp add lighthouse -- lighthouse mcp`
6. Check it: `lighthouse status` names the station and its mode, and `lighthouse lamp-check` passes.

## What this repo is for

It's yours and private. Keep the station's own notes here: why it was named what it was, which repos its tokens cover
and when they expire, and anything else you'd want if you set it up again. **Never put a token, key, muster words or
private term in it.** Those live in the Keychain and in `~/.lighthouse`, which never leaves the machine.

The intake log and the logbook stay in `~/.lighthouse`. `lighthouse verify-log` checks that nothing in them was
changed after it was written.

`standards/` is a starting point for a Lamplighter's charts. See `standards/README.md`.

`scripts/leak-check.sh` looks for email addresses and committed binaries, and runs on every push (`.github/workflows/leak-check.yml`).
Run it locally too, pointed at your Lighthouse terms list so you keep only one:
`LEAK_PRIVATE_TERMS=~/.lighthouse/private-terms.txt bash scripts/leak-check.sh`. It then prints the names of any files
with a private term in them (never the term), so keep private terms out of file names too.
