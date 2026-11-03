"""Triage how far each rendered screen sits from its design reference.

  py -3 -I tool/dev/drift_report.py
  py -3 -I tool/dev/drift_report.py --shots build/shots --out D:/tmp/drift

Pairs every build/shots/<key>-<theme>[-state].png with the design render in
D:/tmp/design-ref/<key>/<key>-<theme>-full.png, then reports two numbers per
pair:

  height    rendered content height / design content height
  profile   correlation of the per-row "ink profile" (the fraction of pixels
            in each row that differ from that row's background), which tracks
            where bands of content and whitespace fall down the page

This is TRIAGE, not a gate. Flutter and a browser rasterise type and curves
differently, so even a faithful port never matches pixel for pixel. A low
profile correlation or a height ratio far from 1.0 means "look at this screen
first"; it never means the screen is wrong, and a high score never means the
screen is right. Only reading the side-by-side comparison does that.

Writes <out>/INDEX.md (worst first) and <out>/<name>.png side-by-side sheets.
"""
import argparse
import re
from pathlib import Path

import numpy as np
from PIL import Image

WIDTH = 780  # 390 CSS px at 2x


def load(path):
    image = Image.open(path).convert('RGB')
    if image.width != WIDTH:
        image = image.resize((WIDTH, round(image.height * WIDTH / image.width)), Image.LANCZOS)
    return image


def ink_profile(image, rows=600):
    """Fraction of each row that departs from that row's own background."""
    grey = np.asarray(image.convert('L'), dtype=np.float32)
    if grey.shape[0] < 2:
        return np.zeros(rows, dtype=np.float32)
    background = np.median(grey, axis=1, keepdims=True)
    ink = (np.abs(grey - background) > 10).mean(axis=1)
    # Resample to a fixed length so screens of different heights compare.
    source = np.linspace(0, 1, len(ink))
    target = np.linspace(0, 1, rows)
    return np.interp(target, source, ink).astype(np.float32)


def correlation(a, b):
    a = a - a.mean()
    b = b - b.mean()
    denominator = float(np.linalg.norm(a) * np.linalg.norm(b))
    return float(np.dot(a, b) / denominator) if denominator else 0.0


def sheet(design, shot, out):
    """Both screens whole, side by side, scaled to fit one viewable sheet."""
    height = max(design.height, shot.height)
    scale = min(1.0, 1400 / height)
    size = (round(WIDTH * scale), round(height * scale))
    canvas = Image.new('RGB', (size[0] * 2 + 16, size[1] + 22), (255, 255, 255))
    for index, image in enumerate((design, shot)):
        pane = image.resize((size[0], round(image.height * scale)), Image.LANCZOS)
        canvas.paste(pane, (index * (size[0] + 16), 22))
    canvas.save(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--shots', default='build/shots')
    parser.add_argument('--ref', default='D:/tmp/design-ref')
    parser.add_argument('--out', default='D:/tmp/drift')
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for png in sorted(Path(args.shots).glob('*.png')):
        match = re.match(r'^(?P<key>[A-Za-z]+?)-(?P<theme>light|dark)(?P<state>-.+)?$', png.stem)
        if not match:
            rows.append((None, png.name, '-', '-', 'name is not <key>-<light|dark>[-state]'))
            continue
        key, theme = match.group('key'), match.group('theme')
        reference = Path(args.ref) / key / f'{key}-{theme}-full.png'
        if not reference.exists():
            rows.append((None, png.name, '-', '-', f'no design reference at {reference}'))
            continue
        design, shot = load(reference), load(png)
        ratio = shot.height / design.height
        score = correlation(ink_profile(design), ink_profile(shot))
        name = f'{png.stem}.png'
        sheet(design, shot, out / name)
        rows.append((score, png.name, f'{ratio:.2f}', f'{score:.2f}', f'[sheet]({name})'))

    rows.sort(key=lambda r: (r[0] is not None, r[0] if r[0] is not None else 0))
    lines = [
        '# Design drift triage', '',
        'Triage only. Flutter and a browser rasterise differently, so a faithful',
        'port never matches pixel for pixel: a low score means "look here first",',
        'not "this is wrong". Read the side-by-side sheet before judging a screen.', '',
        '| Shot | Height ratio | Row-profile correlation | Sheet |',
        '| --- | --- | --- | --- |',
    ]
    lines += [f'| {name} | {ratio} | {score} | {note} |' for _, name, ratio, score, note in rows]
    (out / 'INDEX.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'{len(rows)} shots -> {out / "INDEX.md"}')
    for _, name, ratio, score, note in rows[:12]:
        print(f'  {name:42} height={ratio:>5} profile={score:>6}  {note}')


if __name__ == '__main__':
    main()
