"""Build the CycleCare icon font from the approved redesign's SVG family.

The redesign ships 168 stroked SVG icons on a 24-unit grid (1.7 stroke, round
caps and joins, currentColor). Flutter's icon API is font based and every
screen already speaks IconData, so the family is compiled into a TrueType font
rather than drawn through an SVG package at runtime:

  * strokes are expanded into filled outlines with Skia (skia-pathops), the
    same stroker family the browser uses, so a glyph draws what the SVG draws
  * SVG paint order is honoured: a child filled with the paper colour (the
    sliders icon's knobs) knocks out the ink beneath it before its own stroke
    is added, which is what that fill does on a paper surface
  * code points live in the Private Use Area and are recorded in
    codepoints.json, so a later icon is appended instead of renumbering

Outputs:
  assets/fonts/CycleCareIcons.ttf
  lib/core/theme/app_icons.dart          (generated: edit DART_HEADER below)

Usage:  py -3 tool/icons/build_icon_font.py
Needs:  fonttools, skia-pathops
"""
import json
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.areaPen import AreaPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.reverseContourPen import ReverseContourPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path

ROOT = Path(__file__).resolve().parents[2]
SVG_DIR = ROOT / 'tool' / 'icons' / 'svg'
MANIFEST = ROOT / 'tool' / 'icons' / 'manifest.json'
CODEPOINTS = ROOT / 'tool' / 'icons' / 'codepoints.json'
FONT_OUT = ROOT / 'assets' / 'fonts' / 'CycleCareIcons.ttf'
DART_OUT = ROOT / 'lib' / 'core' / 'theme' / 'app_icons.dart'

FAMILY = 'CycleCareIcons'
SVG_NS = '{http://www.w3.org/2000/svg}'
GRID = 24.0
UPM = 1200
SCALE = UPM / GRID
KAPPA = 0.5522847498307936
FIRST_CODEPOINT = 0xE000

# Directional glyphs. Flutter mirrors these under a right-to-left locale, the
# way Material's own chevrons, undo and logout glyphs behave.
MIRRORED = {'back', 'forward', 'arrowForward', 'undo', 'logout'}


# ── Geometry ────────────────────────────────────────────────────────────────

def _num(el, attr, default=0.0):
    value = el.get(attr)
    return default if value is None else float(value)


def _ellipse(pen, cx, cy, rx, ry):
    k = KAPPA
    pen.moveTo((cx + rx, cy))
    pen.curveTo((cx + rx, cy + k * ry), (cx + k * rx, cy + ry), (cx, cy + ry))
    pen.curveTo((cx - k * rx, cy + ry), (cx - rx, cy + k * ry), (cx - rx, cy))
    pen.curveTo((cx - rx, cy - k * ry), (cx - k * rx, cy - ry), (cx, cy - ry))
    pen.curveTo((cx + k * rx, cy - ry), (cx + rx, cy - k * ry), (cx + rx, cy))
    pen.closePath()


def _rect(pen, x, y, w, h, rx, ry):
    if rx <= 0 or ry <= 0:
        pen.moveTo((x, y))
        pen.lineTo((x + w, y))
        pen.lineTo((x + w, y + h))
        pen.lineTo((x, y + h))
        pen.closePath()
        return
    k = KAPPA
    pen.moveTo((x + rx, y))
    pen.lineTo((x + w - rx, y))
    pen.curveTo((x + w - rx + k * rx, y), (x + w, y + ry - k * ry), (x + w, y + ry))
    pen.lineTo((x + w, y + h - ry))
    pen.curveTo((x + w, y + h - ry + k * ry), (x + w - rx + k * rx, y + h), (x + w - rx, y + h))
    pen.lineTo((x + rx, y + h))
    pen.curveTo((x + rx - k * rx, y + h), (x, y + h - ry + k * ry), (x, y + h - ry))
    pen.lineTo((x, y + ry))
    pen.curveTo((x, y + ry - k * ry), (x + rx - k * rx, y), (x + rx, y))
    pen.closePath()


def _multiply(m, t):
    a1, b1, c1, d1, e1, f1 = m
    a2, b2, c2, d2, e2, f2 = t
    return (a1 * a2 + c1 * b2, b1 * a2 + d1 * b2,
            a1 * c2 + c1 * d2, b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1, b1 * e2 + d1 * f2 + f1)


def _transform(spec):
    m = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', spec):
        v = [float(a) for a in re.split(r'[\s,]+', args.strip()) if a]
        if name == 'matrix':
            t = tuple(v)
        elif name == 'translate':
            t = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            t = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == 'rotate':
            a = math.radians(v[0])
            c, s = math.cos(a), math.sin(a)
            cx, cy = (v[1], v[2]) if len(v) == 3 else (0.0, 0.0)
            t = (c, s, -s, c, cx - c * cx + s * cy, cy - s * cx - c * cy)
        else:
            raise ValueError(f'unsupported transform {name}()')
        m = _multiply(m, t)
    return m


def _geometry(el):
    """The element's outline in SVG user units, or None for non-drawing nodes."""
    tag = el.tag.replace(SVG_NS, '')
    if tag in ('title', 'desc'):
        return None
    path = pathops.Path()
    pen = path.getPen()
    if tag == 'path':
        parse_path(el.get('d'), pen)
    elif tag == 'circle':
        r = _num(el, 'r')
        _ellipse(pen, _num(el, 'cx'), _num(el, 'cy'), r, r)
    elif tag == 'ellipse':
        _ellipse(pen, _num(el, 'cx'), _num(el, 'cy'), _num(el, 'rx'), _num(el, 'ry'))
    elif tag == 'rect':
        w, h = _num(el, 'width'), _num(el, 'height')
        rx, ry = el.get('rx'), el.get('ry')
        rx = float(rx) if rx is not None else (float(ry) if ry is not None else 0.0)
        ry = float(ry) if ry is not None else rx
        _rect(pen, _num(el, 'x'), _num(el, 'y'), w, h, min(rx, w / 2), min(ry, h / 2))
    else:
        raise ValueError(f'unsupported element <{tag}>')
    spec = el.get('transform')
    if spec:
        path = path.transform(*_transform(spec))
    return path


def _in_place(path, result):
    """skia-pathops mutates some paths in place and returns others."""
    return result if isinstance(result, pathops.Path) else path


def _without_conics(path):
    # Skia's stroker draws round caps and joins as conic sections, which
    # neither TrueType nor the boolean ops accept. The tolerance is in font
    # units (UPM 1200), so 0.25 is far below anything visible at icon sizes.
    return _in_place(path, path.convertConicsToQuads(0.25))


def _stroked(path, width):
    outline = pathops.Path()
    outline.addPath(path)
    outline = _in_place(outline, outline.stroke(
        width, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4.0))
    return _without_conics(outline)


def _to_em(path):
    # SVG is y-down on a 24 grid; a glyph is y-up on the em. Flipping before
    # stroking keeps every tolerance below in font units.
    return path.transform(SCALE, 0, 0, -SCALE, 0, UPM)


def _fill_kind(value):
    if value in (None, 'none'):
        return None
    return 'ink' if value == 'currentColor' else 'knockout'


def icon_outline(svg_file):
    """Union of everything the SVG paints in currentColor, in SVG units."""
    root = ET.parse(svg_file).getroot()
    root_fill = root.get('fill', 'black')
    root_stroke = root.get('stroke', 'none')
    root_width = float(root.get('stroke-width', '1'))
    if root.get('stroke-linecap', 'round') != 'round' or root.get('stroke-linejoin', 'round') != 'round':
        raise ValueError(f'{svg_file.name}: only round caps and joins are supported')
    ink = pathops.Path()
    drawn = 0
    for el in root:
        geometry = _geometry(el)
        if geometry is None:
            continue
        drawn += 1
        geometry = _to_em(geometry)
        fill = _fill_kind(el.get('fill', root_fill))
        if fill == 'knockout':
            ink = pathops.op(ink, geometry, pathops.PathOp.DIFFERENCE)
        elif fill == 'ink':
            ink = pathops.op(ink, geometry, pathops.PathOp.UNION)
        if el.get('stroke', root_stroke) != 'none':
            width = float(el.get('stroke-width', root_width)) * SCALE
            ink = pathops.op(ink, _stroked(geometry, width), pathops.PathOp.UNION)
    if not drawn:
        raise ValueError(f'{svg_file.name}: nothing to draw')
    # An inline <svg> clips to its viewport, so strokes that run past the
    # 24-unit box (linkOff's link ends, petBunny's ears) are cut off in the
    # design. Clipping to the em square reproduces that edge exactly.
    box = pathops.Path()
    box_pen = box.getPen()
    box_pen.moveTo((0, 0))
    box_pen.lineTo((UPM, 0))
    box_pen.lineTo((UPM, UPM))
    box_pen.lineTo((0, UPM))
    box_pen.closePath()
    return pathops.op(ink, box, pathops.PathOp.INTERSECTION)


def glyph_for(svg_file):
    """The icon as a TrueType glyph, filling the em box Icon() lays out."""
    ink = _without_conics(pathops.simplify(icon_outline(svg_file), fix_winding=True))
    recording = RecordingPen()
    ink.draw(recording)
    area = AreaPen()
    recording.replay(area)
    tt = TTGlyphPen(None)
    target = Cu2QuPen(tt, max_err=0.5)
    # TrueType wants clockwise outer contours: negative area in y-up space.
    recording.replay(ReverseContourPen(target) if area.value > 0 else target)
    return tt.glyph()


# ── Font and Dart ───────────────────────────────────────────────────────────

def load_codepoints(names):
    known = json.loads(CODEPOINTS.read_text(encoding='utf-8')) if CODEPOINTS.exists() else {}
    next_cp = max([int(v, 16) for v in known.values()] + [FIRST_CODEPOINT - 1]) + 1
    for name in names:
        if name not in known:
            known[name] = f'{next_cp:04X}'
            next_cp += 1
    CODEPOINTS.write_text(json.dumps(known, indent=2) + '\n', encoding='utf-8')
    return {name: int(known[name], 16) for name in names}


def build_font(names, codepoints):
    glyphs = {'.notdef': TTGlyphPen(None).glyph()}
    for name in names:
        glyphs[name] = glyph_for(SVG_DIR / f'{name}.svg')
    order = ['.notdef'] + names
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({codepoints[n]: n for n in names})
    fb.setupGlyf(glyphs)
    glyf = fb.font['glyf']
    fb.setupHorizontalMetrics({gn: (UPM, getattr(glyf[gn], 'xMin', 0)) for gn in order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({
        'familyName': FAMILY,
        'styleName': 'Regular',
        'uniqueFontIdentifier': f'{FAMILY}-Regular',
        'fullName': FAMILY,
        'psName': f'{FAMILY}-Regular',
        'version': 'Version 1.000',
        'copyright': 'CycleCare semantic icon family, from the approved redesign handoff.',
    })
    fb.setupOS2(version=4, sTypoAscender=UPM, sTypoDescender=0, sTypoLineGap=0,
                usWinAscent=UPM, usWinDescent=0, fsSelection=0xC0)
    fb.setupPost()
    if 'maxp' not in fb.font:
        fb.setupMaxp()
    FONT_OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(FONT_OUT))


DART_HEADER = '''// GENERATED by tool/icons/build_icon_font.py. Do not edit by hand: change
// the SVGs in tool/icons/svg (or the header template in the script) and
// re-run `py -3 tool/icons/build_icon_font.py`.

import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Icon registry
//
// The approved redesign's semantic icon family: 168 icons drawn on a 24-unit
// grid with a 1.7 stroke and round caps (redesign/assets/icons). They are
// compiled into the bundled `CycleCareIcons` font, so an icon is an ordinary
// IconData: it takes its colour and size from IconTheme, works in const
// contexts, ships offline, and is tree-shaken in release builds like
// Material's glyphs.
//
// Name an icon for what it means, not what it depicts. Several meanings share
// one drawing on purpose (flow, period and discharge are all the drop), so a
// call site reads `AppIcons.discharge` and a later redraw of that one meaning
// is a change to its SVG rather than a sweep through every screen.
//
// A new meaning gets a new SVG in the same family — 24 grid, 1.7 stroke,
// round caps and joins, currentColor — and a re-run of the script. Do not
// reach for Material's Icons.* or an emoji: the plan forbids mixing families.
// ─────────────────────────────────────────────────────────────────────────────

/// Semantic icons from the redesign family.
class AppIcons {
  AppIcons._();

  static const String fontFamily = '%(family)s';

%(constants)s

  /// Every icon by its semantic name, for data-driven UI such as the logging
  /// catalogue, whose fields and options name their icon as a string.
  static const Map<String, IconData> byName = <String, IconData>{
%(entries)s
  };

  /// The icon for a catalogue name, or [help] for a name with no drawing.
  static IconData named(String name) => byName[name] ?? help;
}
'''


def write_dart(names, codepoints):
    constants = []
    for name in names:
        mirror = ', matchTextDirection: true' if name in MIRRORED else ''
        constants.append(
            f'  static const IconData {name} =\n'
            f'      IconData(0x{codepoints[name]:04x}, fontFamily: fontFamily{mirror});')
    entries = [f"    '{name}': {name}," for name in names]
    DART_OUT.write_text(DART_HEADER % {
        'family': FAMILY,
        'constants': '\n'.join(constants),
        'entries': '\n'.join(entries),
    }, encoding='utf-8')


def main():
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    names = [entry['name'] for entry in manifest]
    bad = [n for n in names if not re.fullmatch(r'[a-z][A-Za-z0-9]*', n)]
    if bad:
        raise SystemExit(f'not valid Dart identifiers: {bad}')
    missing = [n for n in names if not (SVG_DIR / f'{n}.svg').exists()]
    if missing:
        raise SystemExit(f'manifest names without an SVG: {missing}')
    codepoints = load_codepoints(names)
    build_font(names, codepoints)
    write_dart(names, codepoints)
    print(f'{len(names)} icons -> {FONT_OUT.relative_to(ROOT)} ({FONT_OUT.stat().st_size} bytes)')
    print(f'registry -> {DART_OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
