"""Generate the backup slides (one per thesis figure and listing) into backup.md.

Figures, captions, chapters and numbers are read from the compiled thesis with
`typst`, so the slides always match the PDF. Images are copied into
public/backup/. Run from anywhere: `python3 scripts/backup.py`.
"""

import html
import json
import shutil
import subprocess
from pathlib import Path

SLIDES = Path(__file__).resolve().parent.parent
THESIS = SLIDES.parent.parent
CHAPTERS = THESIS / "chapters"
IMAGES = SLIDES / "public" / "backup"

# Short entries for the table of contents; the slide itself shows the full caption.
SHORT_TITLES = {
    "img-fm": "Frequency modulation",
    "img-vox": "VOX tones",
    "img-vis": "VIS code",
    "img-rgb-vs-yuv": "RGB vs. YUV",
    "img-robot36-lines": "Robot 36 scan lines",
    "img-ibd-general": "IBD general system",
    "img-ibd-move-iiia": "IBD MOVE-IIIa",
    "img-pkg-software": "Package diagram",
    "img-ibd-sstv-crate": "IBD sstv encoding",
    "list-sstv-encoding": "sstv encoding usage",
    "img-act-encoder": "Activity Encoder",
    "img-stm-sstv-system": "State machine system",
    "list-camera-trait": "Camera trait",
    "list-audio-channel-trait": "AudioChannel trait",
    "list-command-link-trait": "CommandLink trait",
    "img-act-transmit-sstv": "Activity transmission",
    "img-stm-updating": "State machine updating",
    "list-error-handling": "Error handling",
    "list-test-robot36-mode": "Test transmission time",
    "list-test-shared-pair": "Test shared pair",
    "list-test-synthesizer": "Test synthesizer",
    "list-fake-camera": "FakeCamera",
    "list-test-transmit-sstv": "Test single camera",
    "list-test-transmit-sstv-non-working": "Test empty slots",
    "img-test-setup": "Test setup",
    "list-test-both-cameras": "Test both cameras",
    "list-test-rgb-only": "Test RGB only",
    "list-test-busy-available": "Test busy / available",
    "list-test-update-successful": "Test update successful",
    "list-test-update-incomplete": "Test update incomplete",
    "list-test-update-corrupt": "Test update corrupt",
    "list-test-update-chunk-incomplete": "Test short chunk",
    "list-test-update-data-before-begin": "Test data before begin",
    "list-test-update-end-before-begin": "Test end before begin",
    "list-test-update-wrong-offset": "Test wrong offset",
    "list-size-commands": "Firmware size commands",
    "list-main-comparison": "main() comparison",
    "img-tab5-decoding": "Tab5 decoding",
}

LANGS = {"shell-unix-generic": "bash"}
SUPPLEMENT = {"image": "Figure", "raw": "Listing"}


def typst(*args: str):
    out = subprocess.run(["typst", *args], cwd=THESIS, capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def caption_html(node) -> str:
    """Render a caption content tree as HTML; citations are dropped to keep the slide clean."""
    if isinstance(node, list):
        return "".join(caption_html(n) for n in node)
    func = node.get("func")
    if func == "text":
        return html.escape(node["text"])
    if func == "space":
        return " "
    if func == "raw":
        return f"<code>{html.escape(node['text'])}</code>"
    if func == "smartquote":
        return "“" if node.get("double", True) else "’"
    if func == "symbol":
        return html.escape(node.get("text", ""))
    if func == "ref":
        return ""
    if func == "link":
        return caption_html(node["body"])
    if func in ("sequence", "caption"):
        return caption_html(node.get("children") or node.get("body"))
    return caption_html(node["body"]) if "body" in node else ""


def raws_in(node) -> list:
    """All code blocks inside a content tree, in document order."""
    if isinstance(node, list):
        return [r for n in node for r in raws_in(n)]
    if not isinstance(node, dict):
        return []
    if node.get("func") == "raw":
        return [node]
    return [r for v in node.values() for r in raws_in(v)]


def code_block(raw) -> str:
    lang = LANGS.get(raw.get("lang"), raw.get("lang") or "")
    return f"```{lang}\n{raw['text'].rstrip()}\n```"


def code_size(lines: int) -> float:
    """Pick a code font size so the longest listings still fit the slide height."""
    if lines <= 14:
        return 18
    if lines <= 22:
        return 15
    if lines <= 30:
        return 12.5
    return 11


def main():
    figures = typst("query", "thesis.typ", "figure")
    meta = typst(
        "eval",
        'query(figure).map(it => (chapter: counter(heading).at(it.location()).first(), number: it.counter.at(it.location()).first()))',
        "--in", "thesis.typ", "--format", "json",
    )
    chapters = {
        h["n"]: h["t"]["text"]
        for h in typst("eval", 'query(heading.where(level: 1, outlined: true)).filter(it => it.numbering == "1.1").map(it => (n: counter(heading).at(it.location()).first(), t: it.body))', "--in", "thesis.typ", "--format", "json")
        if h["t"].get("func") == "text"
    }

    if IMAGES.exists():
        shutil.rmtree(IMAGES)
    IMAGES.mkdir(parents=True)

    slides = []
    for fig, m in zip(figures, meta):
        kind = fig["kind"]
        if kind not in SUPPLEMENT:
            continue
        label = fig["label"].strip("<>")
        body = fig["body"]
        title = f"{SUPPLEMENT[kind]} {m['number']}"

        if body["func"] == "image":
            src = (CHAPTERS / body["source"]).resolve()
            shutil.copy(src, IMAGES / src.name)
            content = f'<img class="backup-figure" src="/backup/{src.name}" />'
        elif body["func"] == "raw":
            lines = body["text"].count("\n") + 1
            content = f'<div class="backup-code" style="--slidev-code-font-size: {code_size(lines)}px">\n\n{code_block(body)}\n\n</div>'
        elif body["func"] == "grid":
            raws = raws_in(body["children"])
            lines = max(r["text"].count("\n") + 1 for r in raws)
            columns = "\n".join(f"<div>\n\n{code_block(r)}\n\n</div>" for r in raws)
            content = f'<div class="backup-code backup-columns" style="--slidev-code-font-size: {code_size(lines)}px">\n{columns}\n</div>'
        else:
            raise SystemExit(f"unsupported figure body {body['func']} in {label}")

        frontmatter = "\n".join([
            "---",
            "# Generated by scripts/backup.py from the thesis; edit the script, not this file.",
            "layout: backup",
            f"figure: {json.dumps(title)}",
            f"short: {json.dumps(SHORT_TITLES.get(label, label))}",
            f"chapter: {json.dumps(chapters.get(m['chapter'], ''))}",
            "---",
        ])
        caption = f'<div class="backup-caption"><b>{title}:</b> {caption_html(fig["caption"]["body"])}</div>'
        slides.append(f"{frontmatter}\n\n{content}\n\n{caption}\n")

    (SLIDES / "backup.md").write_text("\n".join(slides))
    print(f"{len(slides)} backup slides written")


if __name__ == "__main__":
    main()
