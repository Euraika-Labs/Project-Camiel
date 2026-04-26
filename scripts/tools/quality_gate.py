#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable, NamedTuple
from urllib.parse import unquote, urlparse


IGNORED_DIRS = {
    ".git",
    ".godot",
    ".venv",
    "__pycache__",
    "builds",
    "dist",
    "node_modules",
    "tmp",
}

BINARY_EXTENSIONS = {
    ".exe",
    ".ico",
    ".jpg",
    ".jpeg",
    ".ogg",
    ".png",
    ".ttf",
    ".wav",
    ".webp",
    ".zip",
}

TEXT_EXTENSIONS = {
    "",
    ".cfg",
    ".gd",
    ".gitignore",
    ".godot",
    ".import",
    ".json",
    ".md",
    ".py",
    ".tres",
    ".tscn",
    ".txt",
    ".uid",
    ".yaml",
    ".yml",
}

GODOT_RESOURCE_EXTENSIONS = {".cfg", ".gd", ".godot", ".tres", ".tscn"}
FORBIDDEN_SCAN_EXEMPTIONS = {
    Path("scripts/tools/quality_gate.py"),
    Path("tests/test_quality_gate.py"),
}

FORBIDDEN_PATTERNS = [
    ("AI disclaimer", re.compile(r"\bas an ai\b", re.IGNORECASE)),
    ("AI disclaimer", re.compile(r"\bas a large language model\b", re.IGNORECASE)),
    ("AI disclaimer", re.compile(r"\bai language model\b", re.IGNORECASE)),
    ("unfinished task marker", re.compile(r"\bTODO\b", re.IGNORECASE)),
    ("unfinished task marker", re.compile(r"\bFIXME\b", re.IGNORECASE)),
    ("unfinished task marker", re.compile(r"\bTBD\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\blorem ipsum\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\bsample text\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\bexample text\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\bdummy\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\breplace me\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\byour text here\b", re.IGNORECASE)),
    ("placeholder copy", re.compile(r"\binsert .{0,40} here\b", re.IGNORECASE)),
    ("unfinished promise", re.compile(r"\bcoming soon\b", re.IGNORECASE)),
]

MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
GODOT_RESOURCE_RE = re.compile(r"res://([^\"'\]\)\s]+)")


class Finding(NamedTuple):
    code: str
    path: str
    line: int
    message: str


def normalize_path(path: Path) -> Path:
    return Path(path.as_posix())


def is_ignored(path: Path) -> bool:
    return any(part in IGNORED_DIRS for part in path.parts)


def is_text_file(path: Path) -> bool:
    if path.suffix.lower() in BINARY_EXTENSIONS:
        return False
    return path.suffix.lower() in TEXT_EXTENSIONS or path.name in {".editorconfig", ".gitattributes", "LICENSE"}


def collect_files(root: Path) -> list[Path]:
    git_files = collect_git_files(root)
    if git_files:
        return git_files

    files: list[Path] = []
    for path in root.rglob("*"):
        if path.is_file():
            relative = path.relative_to(root)
            if not is_ignored(relative):
                files.append(normalize_path(relative))
    return sorted(files)


def collect_git_files(root: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
            cwd=root,
            check=True,
            capture_output=True,
            text=False,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []

    entries = result.stdout.decode("utf-8", errors="replace").split("\0")
    files = [normalize_path(Path(entry)) for entry in entries if entry and not is_ignored(Path(entry))]
    return sorted(files)


def read_text(root: Path, relative_path: Path) -> str:
    return (root / relative_path).read_text(encoding="utf-8", errors="replace")


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def check_required_files(root: Path) -> list[Finding]:
    required = [
        "README.md",
        "CODE_OF_CONDUCT.md",
        "CONTRIBUTING.md",
        "LICENSE",
        "SECURITY.md",
        "SUPPORT.md",
        ".github/PULL_REQUEST_TEMPLATE.md",
        ".github/dependabot.yml",
        ".github/workflows/ci.yml",
        ".github/workflows/codeql.yml",
    ]

    findings: list[Finding] = []
    for relative in required:
        if not (root / relative).is_file():
            findings.append(
                Finding(
                    "missing-required-file",
                    relative,
                    1,
                    "Required community, security, or CI file is missing.",
                )
            )
    return findings


def check_empty_files(root: Path, files: Iterable[Path]) -> list[Finding]:
    findings: list[Finding] = []
    for relative in files:
        path = root / relative
        if path.is_file() and path.stat().st_size == 0:
            findings.append(Finding("empty-file", relative.as_posix(), 1, "Tracked file is empty."))
    return findings


def check_forbidden_phrases(root: Path, files: Iterable[Path]) -> list[Finding]:
    findings: list[Finding] = []
    for relative in files:
        if relative in FORBIDDEN_SCAN_EXEMPTIONS or not is_text_file(relative):
            continue

        text = read_text(root, relative)
        for offset, line in enumerate_lines_with_offsets(text):
            if "quality-gate: allow forbidden-phrase" in line:
                continue
            for label, pattern in FORBIDDEN_PATTERNS:
                if pattern.search(line):
                    findings.append(
                        Finding(
                            "forbidden-phrase",
                            relative.as_posix(),
                            line_number(text, offset),
                            f"Remove {label}: {pattern.pattern}",
                        )
                    )
    return findings


def enumerate_lines_with_offsets(text: str) -> Iterable[tuple[int, str]]:
    offset = 0
    for line in text.splitlines(keepends=True):
        yield offset, line
        offset += len(line)


def check_markdown_links(root: Path, files: Iterable[Path]) -> list[Finding]:
    findings: list[Finding] = []
    for relative in files:
        if relative.suffix.lower() != ".md":
            continue

        text = read_text(root, relative)
        for match in MARKDOWN_LINK_RE.finditer(text):
            target = match.group(1).strip()
            if is_external_link(target):
                continue

            target_without_anchor = target.split("#", 1)[0]
            if not target_without_anchor:
                continue

            decoded = unquote(target_without_anchor)
            target_path = (root / relative.parent / decoded).resolve()
            try:
                target_path.relative_to(root.resolve())
            except ValueError:
                findings.append(
                    Finding(
                        "unsafe-markdown-link",
                        relative.as_posix(),
                        line_number(text, match.start()),
                        f"Markdown link points outside the repository: {target}",
                    )
                )
                continue

            if not target_path.exists():
                findings.append(
                    Finding(
                        "broken-markdown-link",
                        relative.as_posix(),
                        line_number(text, match.start()),
                        f"Markdown link target does not exist: {target}",
                    )
                )
    return findings


def is_external_link(target: str) -> bool:
    parsed = urlparse(target)
    return parsed.scheme in {"http", "https", "mailto"}


def check_godot_resource_paths(root: Path, files: Iterable[Path]) -> list[Finding]:
    findings: list[Finding] = []
    for relative in files:
        if relative.suffix.lower() not in GODOT_RESOURCE_EXTENSIONS:
            continue

        text = read_text(root, relative)
        for match in GODOT_RESOURCE_RE.finditer(text):
            resource_path = unquote(match.group(1)).split("#", 1)[0]
            if not resource_path or resource_path.startswith(".godot/"):
                continue

            if not (root / resource_path).exists():
                findings.append(
                    Finding(
                        "missing-godot-resource",
                        relative.as_posix(),
                        line_number(text, match.start()),
                        f"Godot resource path does not exist: res://{resource_path}",
                    )
                )
    return findings


def check_asset_import_metadata(root: Path, files: Iterable[Path]) -> list[Finding]:
    findings: list[Finding] = []
    file_set = {normalize_path(path) for path in files}
    for relative in file_set:
        if relative.suffix.lower() == ".png" and relative.parts[:1] == ("assets",):
            import_file = normalize_path(Path(relative.as_posix() + ".import"))
            if import_file not in file_set and not (root / import_file).is_file():
                findings.append(
                    Finding(
                        "missing-godot-import",
                        relative.as_posix(),
                        1,
                        "PNG asset is missing its Godot .import metadata file.",
                    )
                )
    return findings


def run_checks(root: Path, files: Iterable[Path] | None = None) -> list[Finding]:
    root = root.resolve()
    full_scan = files is None
    selected_files = [normalize_path(path) for path in files] if files is not None else collect_files(root)

    findings: list[Finding] = []
    if full_scan:
        findings.extend(check_required_files(root))
    findings.extend(check_empty_files(root, selected_files))
    findings.extend(check_forbidden_phrases(root, selected_files))
    findings.extend(check_markdown_links(root, selected_files))
    findings.extend(check_godot_resource_paths(root, selected_files))
    findings.extend(check_asset_import_metadata(root, selected_files))
    return sorted(findings, key=lambda item: (item.path, item.line, item.code, item.message))


def format_github_error(finding: Finding) -> str:
    message = finding.message.replace("%", "%25").replace("\n", "%0A").replace("\r", "%0D")
    return f"::error file={finding.path},line={finding.line},title={finding.code}::{message}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run Project Camiel repository quality gates.")
    parser.add_argument("--root", default=".", help="Repository root to scan.")
    args = parser.parse_args(argv)

    root = Path(args.root)
    findings = run_checks(root)

    if findings:
        for finding in findings:
            if os.getenv("GITHUB_ACTIONS") == "true":
                print(format_github_error(finding))
            else:
                print(f"{finding.path}:{finding.line}: {finding.code}: {finding.message}")
        print(f"Quality gate failed with {len(findings)} finding(s).", file=sys.stderr)
        return 1

    print("Quality gate passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
