# Standards

This folder is a starting point for a Lamplighter's charts. The charts are the standards and practices every vessel
follows. Write each one as its own page here, then publish it with:

```bash
lighthouse chart --path standards/<topic>.md --file <your draft> --notice "What changed, in one line"
```

That signs it, cork-checks it, and adds a dated notice in `notices/`. Vessels see the notice the next time they look.

Keep the charts **work-safe**: no people, employers, machines, addresses or private projects. Every vessel reads them,
including ones on machines you don't fully control. The cork check refuses anything that matches your private terms.

A few pages most fleets start with:

- `standards/writing.md`: how written work should read
- `standards/git.md`: branches, commits, what never gets committed
- `standards/testing.md`: what "tested" means here
- `standards/security.md`: secrets, tokens and what to do after a leak
