#!/usr/bin/env python3
"""
Convert gnatdoc RST output to Markdown.
Usage: python3 tools/rst2md.py [rst_dir] [output_dir]
"""

import re
import sys
import os
from os.path import join

RST_DIR = sys.argv[1] if len(sys.argv) > 1 else "obj/gnatdoc-rst"
OUT_DIR  = sys.argv[2] if len(sys.argv) > 2 else "docs/api-docs"


MOJIBAKE_EMDASH = "\u00e2\u0080\u0094"


def fix_text(text):
    return text.replace(MOJIBAKE_EMDASH, ":")


def slug(name):
    return name.lower().replace(".", "-") + ".md"


def parse_title(text):
    m = re.search(r"^(.+?)\n[*]{2,}", text, re.MULTILINE)
    return m.group(1).strip() if m else ""


def parse_description(text):
    """Extract text between the set_package code block and first section heading."""
    m = re.search(
        r'code-block:: ada\s*\n\s+package\s+\S+\s*$'
        r'(.*?)'
        r'(?:^-----.+$|\Z)',
        text,
        re.MULTILINE | re.DOTALL
    )
    if m:
        desc = m.group(1).strip()
        desc = re.sub(r'^\s*\*\s*', '- ', desc, flags=re.MULTILINE)
        desc = re.sub(r'\n{3,}', '\n\n', desc)
        return desc
    return ""


def parse_blocks(text):
    """Split RST text into (kind, name, decl, params, returns) blocks."""
    blocks = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        m = re.match(r"^\.\. ada:(type|function|procedure)::\s+(.+)$", lines[i])
        if m:
            kind = m.group(1)
            name = m.group(2).strip()
            decl = ""
            i += 1
            while i < len(lines) and lines[i].strip() and lines[i].startswith(" "):
                stripped = lines[i].strip()
                i += 1
                if re.match(r'^:[\w-]+:', stripped):
                    continue
                if decl:
                    decl += "\n"
                decl += stripped
            params = {}
            returns = ""
            while i < len(lines):
                pm = re.match(r'^\s+:parameter\s+(\S+):\s*(.*)', lines[i])
                if pm:
                    pname = pm.group(1)
                    pdesc = pm.group(2).strip()
                    i += 1
                    while i < len(lines) and lines[i].strip() and re.match(r'^\s{4,}', lines[i]):
                        if lines[i].strip():
                            pdesc += " " + lines[i].strip()
                        i += 1
                    params[pname] = pdesc
                elif re.match(r'^\s+:returns:\s*(.*)', lines[i]):
                    rm = re.match(r'^\s+:returns:\s*(.*)', lines[i])
                    returns = rm.group(1).strip()
                    i += 1
                    while i < len(lines) and lines[i].strip() and re.match(r'^\s{4,}', lines[i]):
                        if lines[i].strip():
                            returns += " " + lines[i].strip()
                        i += 1
                elif re.match(r'^\s*\.\. code-block:: ada', lines[i]):
                    i += 1
                    base_indent = None
                    while i < len(lines):
                        if not lines[i].strip():
                            i += 1
                            continue
                        indent = len(lines[i]) - len(lines[i].lstrip())
                        if base_indent is None:
                            base_indent = indent
                        if indent < base_indent:
                            break
                        stripped = lines[i].strip()
                        if re.match(r'^--', stripped):
                            i += 1
                            continue
                        if decl:
                            decl += "\n"
                        decl += stripped
                        i += 1
                elif re.match(r'^\s*\.\. ada:', lines[i]):
                    break
                elif re.match(r'^----', lines[i]):
                    break
                elif re.match(r'^\S', lines[i]) and not lines[i].startswith(" "):
                    break
                else:
                    i += 1
            blocks.append((kind, name, decl, params, returns))
        else:
            i += 1
    return blocks


def parse_ada_annotations(ads_path):
    """Parse .ads file for @param and @return annotations per subprogram."""
    if not os.path.isfile(ads_path):
        return {}
    with open(ads_path) as f:
        lines = f.readlines()
    result = {}
    cur = {"params": {}, "returns": ""}
    in_private = False
    for line in lines:
        s = line.strip()
        if re.match(r'^private$', s):
            in_private = True
            continue
        if in_private:
            continue
        pm = re.match(r'--\s*@param\s+(\S+)\s*(.*)', s)
        s = line.strip()
        pm = re.match(r'--\s*@param\s+(\S+)\s*(.*)', s)
        if pm:
            cur["params"][pm.group(1)] = pm.group(2).strip()
            continue
        rm = re.match(r'--\s*@return\s*(.*)', s)
        if rm:
            cur["returns"] = rm.group(1).strip()
            continue
        sm = re.match(
            r'\s*(?:overriding\s+)?(?:procedure\b|function\b)\s+'
            r'("(?:[^"]|"")+"|\w+)',
            s
        )
        if sm:
            name = sm.group(1)
            result[name] = cur
            cur = {"params": {}, "returns": ""}
    return result


def subprog_short_name(block_name):
    """Extract short name from RST block name e.g. 'function Contains (...)' -> 'Contains'."""
    m = re.match(r'(?:procedure|function)\s+("(?:[^"]|"")+"|\w+)', block_name)
    return m.group(1) if m else block_name


def package_to_ads_path(pkg_name):
    """Convert CRDT.Lww_Element_Sets -> src/crdt-lww_element_sets.ads."""
    return "src/" + "-".join(pkg_name.lower().split(".")) + ".ads"


def render_index(packages):
    lines = ["# CRDT API Reference", "", "## Packages", ""]
    for title in sorted(packages, key=lambda p: (p.count("."), p.lower())):
        lines.append(f"- [{title}]({packages[title]})")
    lines.append("")
    return "\n".join(lines)


def render_package(title, desc, blocks, annotations):
    lines = [f"# {title}", ""]
    if desc:
        lines.append(desc)
        lines.append("")

    sections = {}
    for kind, name, decl, params, returns in blocks:
        sec = {"type": "Types", "function": "Functions", "procedure": "Procedures"}.get(kind, "Other")
        sections.setdefault(sec, []).append((name, decl, (params, returns)))

    for sec in ["Types", "Functions", "Procedures"]:
        items = sections.get(sec)
        if not items:
            continue
        lines.append(f"## {sec}\n")
        for name, decl, params_returns in items:
            params, returns = params_returns
            sname = subprog_short_name(name)
            anno = annotations.get(sname, {})
            lines.append(f"### {name}\n")
            if decl:
                lines.append(f"```ada\n{decl}\n```\n")
            merged = {}
            for pname in sorted(params):
                merged[pname] = params[pname] or anno.get("params", {}).get(pname, "")
            if merged:
                lines.append("| Parameter | Description |")
                lines.append("|-----------|-------------|")
                for pname, pdesc in sorted(merged.items()):
                    lines.append(f"| `{pname}` | {pdesc} |")
                lines.append("")
            rdesc = returns or anno.get("returns", "")
            if rdesc:
                lines.append(f"**Returns:** {rdesc}\n")

    return "\n".join(lines)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    files = sorted(f for f in os.listdir(RST_DIR) if f.endswith(".rst"))
    packages = {}

    for fname in files:
        with open(join(RST_DIR, fname)) as f:
            text = fix_text(f.read())

        title = parse_title(text)
        if not title:
            continue

        desc = parse_description(text)
        blocks = parse_blocks(text)
        ads_path = package_to_ads_path(title)
        annotations = parse_ada_annotations(ads_path)
        fn = slug(title)
        with open(join(OUT_DIR, fn), "w") as f:
            f.write(render_package(title, desc, blocks, annotations))
        packages[title] = fn

    with open(join(OUT_DIR, "index.md"), "w") as f:
        f.write(render_index(packages))

    print(f"Wrote {len(packages)} package docs + index to {OUT_DIR}/")


if __name__ == "__main__":
    main()
