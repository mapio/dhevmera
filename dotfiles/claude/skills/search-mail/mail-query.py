#!/usr/bin/env python3
"""Read-only view of mercurio's mail header index, for a session rather than an IMAP client.

maildir_search.py answers by filling the Search IMAP folder, which a session cannot see and
which it wipes on every run; this reads the same index without writing anything. Piped over
ssh (see SKILL.md), so it needs no deployment and must stay Python 3.9 and stdlib-only.
"""

import argparse
import email
import email.policy
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.home() / "Maildir"
DB = Path.home() / ".maildir_index.db"


def folder_dir(label):
    return ROOT if label == "INBOX" else ROOT / ("." + label.replace("/", "."))


def resolve(folder, filename):
    # Maildir flags live after ":2," and change on read or reply, renaming the file.
    stem = filename.split(":2,")[0]
    for sub in ("cur", "new"):
        for p in (folder_dir(folder) / sub).glob(glob_escape(stem) + "*"):
            if p.name.split(":2,")[0] == stem:
                return p
    return None


def glob_escape(s):
    return "".join(f"[{c}]" if c in "*?[" else c for c in s)


def epoch(day):
    return datetime.strptime(day, "%Y-%m-%d").replace(tzinfo=timezone.utc).timestamp()


def search(db, a):
    where, params = [], []
    for col, pat in (("from_", a.from_), ("recipients", a.to), ("subject", a.subject)):
        if pat:
            where.append(f"{col} LIKE ?")
            params.append(f"%{pat}%")
    if a.folder:
        where.append("folder LIKE ?")
        params.append(a.folder)
    if a.since:
        where.append("date >= ?")
        params.append(epoch(a.since))
    if a.until:
        where.append("date < ?")
        params.append(epoch(a.until) + 86400)
    sql = "SELECT date, folder, filename, from_, subject, recipients FROM messages"
    if where:
        sql += " WHERE " + " AND ".join(where)
    sql += " ORDER BY date DESC LIMIT ?"
    params.append(a.limit)
    for date, folder, filename, from_, subject, recipients in db.execute(sql, params):
        day = datetime.fromtimestamp(date, timezone.utc).strftime("%Y-%m-%d") if date else "?"
        cols = [day, folder, filename, from_ or "", subject or ""]
        if a.recipients:
            cols.append(recipients or "")
        # Headers are stored as folded, so a field can carry newlines and tabs.
        print("\t".join(" ".join(c.split()) for c in cols))


def show(folder, filename):
    path = resolve(folder, filename)
    if path is None:
        sys.exit(f"not found: {folder} {filename} (moved or deleted since indexing)")
    with open(path, "rb") as f:
        msg = email.message_from_binary_file(f, policy=email.policy.default)
    for h in ("Date", "From", "To", "Cc", "Subject", "Message-ID"):
        if msg[h]:
            print(f"{h}: {msg[h]}")
    print()
    body = msg.get_body(preferencelist=("plain", "html"))
    print(body.get_content() if body else "(no text part)")
    names = [p.get_filename() for p in msg.iter_attachments() if p.get_filename()]
    if names:
        print("\nAttachments: " + ", ".join(names))


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--from", dest="from_", help="substring of From (SQL LIKE, case-insensitive ASCII)")
    p.add_argument("--to", help="substring of To/Cc/Bcc")
    p.add_argument("--subject", help="substring of Subject")
    p.add_argument("--folder", help="folder label, LIKE pattern (INBOX, Archived/2024, Archived/%%)")
    p.add_argument("--since", help="YYYY-MM-DD, inclusive")
    p.add_argument("--until", help="YYYY-MM-DD, inclusive")
    p.add_argument("--limit", type=int, default=50)
    p.add_argument("--recipients", action="store_true", help="add To/Cc/Bcc as a last column")
    p.add_argument("--show", nargs=2, metavar=("FOLDER", "FILENAME"), help="print one message")
    a = p.parse_args()
    if a.show:
        show(*a.show)
        return
    db = sqlite3.connect(f"file:{os.fspath(DB)}?mode=ro", uri=True)
    search(db, a)


if __name__ == "__main__":
    main()
