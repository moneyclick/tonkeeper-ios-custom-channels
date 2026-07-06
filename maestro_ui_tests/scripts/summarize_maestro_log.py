#!/usr/bin/env python3
"""
Build a short maestro-ci-summary.txt from a verbose maestro.log (see --debug-output).
Intended for CI: wall clock span, per-flow pass/fail with failure step, suite counts.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path


TS_RE = re.compile(r"^(\d{2}:\d{2}:\d{2}\.\d+)\s+")
# "Running flow omniston_swap_test" (two spaces after runFlow: in some builds)
RUN_FLOW_RE = re.compile(
    r"TestSuiteInteractor\.runFlow:?\s*Running flow\s+([A-Za-z0-9_\-]+)\s*$"
)
# Only flow command failures from the orchestra (not util/CLI [ERROR] noise).
COMMAND_FAILED_RE = re.compile(
    r"^\d{2}:\d{2}:\d{2}\.\d+.*maestro\.orchestra\.Orchestra\.executeCommands:.*CommandFailed:\s*(.*)$"
)
ORCHESTRA_COMMAND_FAILED_ANYWHERE = re.compile(
    r"maestro\.orchestra\.Orchestra\.executeCommands:.*CommandFailed:\s*(.*)$",
    flags=re.MULTILINE,
)
# INFO line: ...runFlow$lambda$17$lambda$9: Assert ... FAILED
STEP_FAILED_RE = re.compile(
    r"maestro\.cli\.runner\.TestSuiteInteractor\.runFlow(?:\$lambda\$\d+)+\s*:\s*(.+?)\s+FAILED\s*$"
)


@dataclass
class FlowResult:
    name: str
    start_line: int
    text: str
    failures: list[str] = field(default_factory=list)
    step_labels: list[str] = field(default_factory=list)

    def has_error(self) -> bool:
        return bool(self.failures)


def _parse_time(line: str) -> datetime | None:
    m = TS_RE.match(line)
    if not m:
        return None
    return datetime.strptime(m.group(1), "%H:%M:%S.%f").replace(
        year=2000, month=1, day=1
    )


def _fmt_duration_s(seconds: float) -> str:
    s = int(round(max(0.0, seconds)))
    m, s = divmod(s, 60)
    h, m = divmod(m, 60)
    if h:
        return f"{h}h {m}m {s}s"
    if m:
        return f"{m}m {s}s"
    return f"{s}s"


def split_by_flows(lines: list[str]) -> list[FlowResult]:
    """Split log into segments, one per 'Running flow name'. Pre-flow prefix is dropped."""
    hits: list[tuple[int, str]] = []
    for i, line in enumerate(lines):
        m = RUN_FLOW_RE.search(line)
        if m:
            hits.append((i, m.group(1)))

    if not hits:
        return []

    out: list[FlowResult] = []
    for j, (start, name) in enumerate(hits):
        end = hits[j + 1][0] if j + 1 < len(hits) else len(lines)
        block = "\n".join(lines[start:end])
        failures: list[str] = []
        step_labels: list[str] = []
        for bline in lines[start:end]:
            cm = COMMAND_FAILED_RE.match(bline.strip())
            if cm:
                failures.append(cm.group(1).strip())
            sm = STEP_FAILED_RE.search(bline)
            if sm:
                step_labels.append(sm.group(1).strip())
        out.append(
            FlowResult(
                name=name, start_line=start, text=block, failures=failures, step_labels=step_labels
            )
        )
    return out


def wall_clock(lines: list[str]) -> tuple[datetime | None, datetime | None, str]:
    first = last = None
    for line in lines:
        t = _parse_time(line)
        if t:
            if first is None:
                first = t
            last = t
    if first and last and last >= first:
        return first, last, _fmt_duration_s((last - first).total_seconds())
    return first, last, "unknown"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", type=Path, required=True, help="Path to maestro.log")
    ap.add_argument("--out", type=Path, help="Write summary here (default: stdout)")
    ap.add_argument("--flow-group", default="", help="e.g. matrix value 'transactions'")
    ap.add_argument(
        "--exit",
        type=int,
        default=None,
        help="maestro process exit code (0 = success). If omitted, inferred from Orchestra CommandFailed lines in log",
    )
    args = ap.parse_args()

    raw = args.log.read_text(encoding="utf-8", errors="replace")
    lines = raw.splitlines()
    t0, t1, wall = wall_clock(lines)
    flows = split_by_flows(lines)
    orchestra_fail_msgs = ORCHESTRA_COMMAND_FAILED_ANYWHERE.findall(raw)

    exit_code = args.exit
    if exit_code is None:
        exit_code = 1 if orchestra_fail_msgs else 0
    overall = "PASSED" if exit_code == 0 else "FAILED"

    n_flows = len(flows)
    n_passed = sum(1 for f in flows if not f.has_error())
    n_failed = n_flows - n_passed
    failed_names = [f.name for f in flows if f.has_error()]

    out_lines: list[str] = [
        "=== Maestro CI summary ===",
    ]
    if args.flow_group:
        out_lines.append(f"flow_group: {args.flow_group}")
    out_lines.append(f"overall: {overall} (exit {exit_code})")
    if n_flows:
        out_lines.append(
            f"flows: {n_flows} total | {n_passed} passed | {n_failed} failed"
        )
        if failed_names:
            out_lines.append(f"failed_flows: {', '.join(failed_names)}")
        passed_only = [f.name for f in flows if not f.has_error()]
        if passed_only:
            out_lines.append(f"passed_flows: {', '.join(passed_only)}")
    else:
        out_lines.append("flows: 0 parsed (no 'Running flow …' lines in log)")
    if t0 and t1:
        t0s = t0.strftime("%H:%M:%S.%f")[:-3]
        t1s = t1.strftime("%H:%M:%S.%f")[:-3]
        out_lines.append(f"wall_time: {wall} (log span {t0s} – {t1s}, local time)")
    else:
        out_lines.append(f"wall_time: {wall}")
    out_lines.append(f"log: {args.log.name}")
    out_lines.append("")

    out_lines.append("Per flow:")
    for fr in flows:
        st = "FAILED" if fr.has_error() else "PASSED"
        out_lines.append(f"  {fr.name}: {st}")
        if fr.has_error():
            if fr.step_labels:
                out_lines.append(f"    failed_step: {fr.step_labels[-1]}")
            elif fr.text:
                m = list(STEP_FAILED_RE.finditer(fr.text))
                if m:
                    out_lines.append(f"    failed_step: {m[-1].group(1).strip()}")
            if fr.failures:
                out_lines.append(f"    error: {fr.failures[-1]}")
    out_lines.append("")

    text = "\n".join(out_lines) + "\n"
    if args.out:
        args.out.write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
