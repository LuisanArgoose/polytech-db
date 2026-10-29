"""Run real PostgreSQL isolation experiments using two persistent psql sessions.

No third-party Python packages. Requires psql or Docker with a running PostgreSQL
container. Only an automatically named scratch schema is modified and removed.
"""

import argparse
import json
import os
from pathlib import Path
import queue
import subprocess
import threading
import time
import uuid


class Session:
    def __init__(self, command, name, journal):
        self.name = name
        self.journal = journal
        self.lines = queue.Queue()
        self.pending = None
        self.process = subprocess.Popen(
            command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, encoding="utf-8", bufsize=1,
        )
        threading.Thread(target=self._read, daemon=True).start()
        self.run("SET client_encoding TO 'UTF8'; SET statement_timeout = '10s'; "
                 "SET lock_timeout = '8s';")
        self.pid = int(self.run("SELECT pg_backend_pid();")[0])

    def _read(self):
        for line in self.process.stdout:
            self.lines.put(line.rstrip("\r\n"))
        self.lines.put(None)

    def send(self, sql):
        if self.pending is not None:
            raise RuntimeError("A statement is already pending")
        marker = "END_" + uuid.uuid4().hex
        self.pending = (marker, sql)
        self.process.stdin.write(sql + "\n\\echo " + marker + " :SQLSTATE\n")
        self.process.stdin.flush()

    def receive(self, expected="00000"):
        marker, sql = self.pending
        rows = []
        deadline = time.monotonic() + 15
        while True:
            line = self.lines.get(timeout=max(0.01, deadline - time.monotonic()))
            if line is None:
                raise RuntimeError(f"Session {self.name} terminated: {rows}")
            if line.startswith(marker + " "):
                state = line.split()[-1]
                break
            rows.append(line)
        self.pending = None
        self.journal.append(dict(session=self.name, sql=sql, output=rows, sqlstate=state))
        if state != expected:
            raise AssertionError(f"{self.name}: expected SQLSTATE {expected}, got {state}: {rows}")
        return rows

    def run(self, sql, expected="00000"):
        self.send(sql)
        return self.receive(expected)

    def close(self):
        if self.process.poll() is None:
            try:
                self.process.stdin.write("ROLLBACK;\n\\q\n")
                self.process.stdin.flush()
                self.process.wait(timeout=12)
            except (OSError, subprocess.TimeoutExpired):
                self.process.kill()
                self.process.wait()
        self.process.stdin.close()
        self.process.stdout.close()


READ = 'SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = \'IVT-21\';'
COUNT = 'SELECT COUNT(*) FROM "StudentGroups" WHERE "CourseYear" = 4;'
COPY_A = '''UPDATE "StudentGroups" SET "StudentCount" =
    (SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'IVT-22')
    WHERE "GroupCode" = 'IVT-21';'''
COPY_B = '''UPDATE "StudentGroups" SET "StudentCount" =
    (SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'IVT-21')
    WHERE "GroupCode" = 'IVT-22';'''


def require(actual, expected):
    if actual != expected:
        raise AssertionError(f"Expected {expected!r}, got {actual!r}")
    return actual


class Experiments:
    def __init__(self, a, b):
        self.a, self.b = a, b
        self.results = []

    def reset(self):
        for session in (self.a, self.b):
            session.run("ROLLBACK;")
        self.a.run('TRUNCATE "StudentGroups";')
        self.a.run('''INSERT INTO "StudentGroups"
            ("Id", "GroupCode", "CourseYear", "StudentCount", "FacultyId") VALUES
            ('00000000-0000-0000-0000-000000000001', 'IVT-21', 4, 24,
             '00000000-0000-0000-0000-000000000010'),
            ('00000000-0000-0000-0000-000000000002', 'IVT-22', 4, 26,
             '00000000-0000-0000-0000-000000000010');''')

    def begin(self, level):
        for session in (self.a, self.b):
            session.run(f"BEGIN ISOLATION LEVEL {level};")
            require(session.run("SHOW transaction_isolation;"), [level.lower()])

    def record(self, level, scenario, **values):
        result = dict(level=level, scenario=scenario, **values)
        self.results.append(result)
        print(json.dumps(result, ensure_ascii=False))

    def state(self):
        return self.a.run('SELECT "StudentCount" FROM "StudentGroups" ORDER BY "GroupCode";')

    def lost_update(self, level):
        self.reset()
        self.begin(level)
        require(self.a.run(READ), ["24"])
        require(self.b.run(READ), ["24"])
        self.a.run('''UPDATE "StudentGroups" SET "StudentCount" = "StudentCount" + 5
                      WHERE "GroupCode" = 'IVT-21';''')
        self.b.send('''UPDATE "StudentGroups" SET "StudentCount" = "StudentCount" + 3
                      WHERE "GroupCode" = 'IVT-21';''')
        # Confirm actual blocking, rather than relying on an arbitrary sleep.
        deadline = time.monotonic() + 5
        while self.a.run(f"SELECT {self.a.pid} = ANY(pg_blocking_pids({self.b.pid}));") != ["t"]:
            if time.monotonic() >= deadline:
                raise AssertionError("B did not wait for A's row lock")
            time.sleep(0.02)
        self.a.run("COMMIT;")
        self.b.receive()
        self.b.run("COMMIT;")
        final = require(self.a.run(READ), ["32"])
        self.record(level, "lost_update_increments", final=final, anomaly=False)

    def dirty_read(self, level):
        self.reset()
        self.begin(level)
        self.a.run('''UPDATE "StudentGroups" SET "StudentCount" = 999
                      WHERE "GroupCode" = 'IVT-21';''')
        before = require(self.b.run(READ), ["24"])
        self.a.run("ROLLBACK;")
        after = require(self.b.run(READ), ["24"])
        self.b.run("COMMIT;")
        self.record(level, "dirty_read", reads=[before, after], anomaly=False)

    def repeated_read(self, level, phantom=False):
        self.reset()
        self.begin(level)
        query = COUNT if phantom else READ
        first = require(self.a.run(query), ["2" if phantom else "24"])
        if phantom:
            self.b.run('''INSERT INTO "StudentGroups"
                ("Id", "GroupCode", "CourseYear", "StudentCount", "FacultyId") VALUES
                ('00000000-0000-0000-0000-000000000003', 'TEST-4', 4, 20,
                 '00000000-0000-0000-0000-000000000010');''')
        else:
            self.b.run('''UPDATE "StudentGroups" SET "StudentCount" = 30
                          WHERE "GroupCode" = 'IVT-21';''')
        self.b.run("COMMIT;")
        anomaly = level != "REPEATABLE READ"
        second = require(self.a.run(query), ["3" if phantom else "30"] if anomaly else first)
        self.a.run("COMMIT;")
        self.record(level, "phantom" if phantom else "non_repeatable_read",
                    reads=[first, second], anomaly=anomaly)

    def serialization(self, level):
        sequential = []
        for order in ((COPY_A, COPY_B), (COPY_B, COPY_A)):
            self.reset()
            for statement in order:
                self.a.run(f"BEGIN ISOLATION LEVEL {level};")
                self.a.run(statement)
                self.a.run("COMMIT;")
            sequential.append(self.state())
        require(sequential, [["26", "26"], ["24", "24"]])
        self.reset()
        self.begin(level)
        self.a.run(COPY_A)
        self.b.run(COPY_B)
        self.a.run("COMMIT;")
        state = "40001" if level == "SERIALIZABLE" else "00000"
        self.b.run("COMMIT;", expected=state)
        final = require(self.state(), ["26", "26"] if state == "40001" else ["26", "24"])
        # Retrying the whole failed transaction is required, not just COMMIT.
        if state == "40001":
            self.b.run(f"BEGIN ISOLATION LEVEL {level};")
            self.b.run(COPY_B)
            self.b.run("COMMIT;")
            require(self.state(), sequential[0])
        self.record(level, "serialization", sequential=sequential,
                    parallel=final, sqlstate=state, anomaly=state == "00000")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--container", help="Running PostgreSQL Docker container; otherwise use local psql")
    parser.add_argument("--database", default=os.environ.get("PGDATABASE", "examdb"))
    parser.add_argument("--user", default=os.environ.get("PGUSER", "postgres"))
    parser.add_argument("--output", type=Path, default=Path(__file__).with_name("04_transaction_results.json"))
    args = parser.parse_args()
    command = ["psql", "-X", "-q", "-A", "-t", "-w", "-v", "VERBOSITY=verbose",
               "-U", args.user, "-d", args.database]
    if args.container:
        command = ["docker", "exec", "-i", "-e", "PGCLIENTENCODING=UTF8", args.container] + command
    schema = "anomaly_" + uuid.uuid4().hex
    journal, sessions = [], []
    report = dict(schema=schema, results=[], journal=journal, success=False)
    try:
        for name in ("A", "B"):
            sessions.append(Session(command, name, journal))
        a, b = sessions
        report["server"] = a.run("SELECT version();")[0]
        report["database"] = a.run("SELECT current_database();")[0]
        a.run(f'CREATE SCHEMA "{schema}";')
        # LIKE copies columns, checks and indexes, but not foreign keys or triggers.
        a.run(f'CREATE TABLE "{schema}"."StudentGroups" '
              '(LIKE exam."StudentGroups" INCLUDING ALL);')
        for session in sessions:
            session.run(f'SET search_path TO "{schema}";')
        experiments = Experiments(a, b)
        report["results"] = experiments.results
        for level in ("READ COMMITTED", "READ UNCOMMITTED"):
            experiments.lost_update(level)
            experiments.dirty_read(level)
            experiments.repeated_read(level)
            experiments.repeated_read(level, phantom=True)
        experiments.repeated_read("REPEATABLE READ")
        experiments.repeated_read("REPEATABLE READ", phantom=True)
        experiments.serialization("REPEATABLE READ")
        experiments.serialization("SERIALIZABLE")
        report["success"] = True
    finally:
        # Close B first to release any lock/transaction left by a failed check.
        try:
            if len(sessions) == 2:
                sessions[1].close()
            if sessions:
                a = sessions[0]
                a.run("ROLLBACK;")
                a.run(f'DROP SCHEMA IF EXISTS "{schema}" CASCADE;')
                report["cleanup"] = True
        finally:
            for session in sessions:
                session.close()
            args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: {len(report['results'])} checks; journal: {args.output.resolve()}")


if __name__ == "__main__":
    main()