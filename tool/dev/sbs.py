"""Side-by-side view of a design reference and a Flutter render.

  py -3 -I /d/tmp/cc-tools/sbs.py DESIGN.png FLUTTER.png OUT.png --top 0 --height 900
  py -3 -I /d/tmp/cc-tools/sbs.py IMAGE.png - OUT.png --top 1200 --height 600   (crop one image)

Both images are scaled to 390 CSS px wide (780 px, i.e. 2x), cropped to the
window [top, top + height] in CSS px, and placed side by side with a ruler
every 50 CSS px, so positions read directly against the *-spec.txt numbers.
Then open OUT.png with the Read tool. Keep --height at or below ~1000 so the
viewer shows it at full resolution.
"""
import argparse

from PIL import Image, ImageDraw

WIDTH = 780  # 390 CSS px at 2x


def window(path, top, height):
    image = Image.open(path).convert('RGB')
    if image.width != WIDTH:
        image = image.resize((WIDTH, round(image.height * WIDTH / image.width)), Image.LANCZOS)
    y0 = top * 2
    y1 = (top + height) * 2
    out = Image.new('RGB', (WIDTH, y1 - y0), (255, 0, 255))
    if y0 < image.height:
        out.paste(image.crop((0, y0, WIDTH, min(y1, image.height))), (0, 0))
    return out, image.height // 2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('left')
    parser.add_argument('right')
    parser.add_argument('out')
    parser.add_argument('--top', type=int, default=0, help='CSS px')
    parser.add_argument('--height', type=int, default=900, help='CSS px')
    args = parser.parse_args()

    panes = [window(args.left, args.top, args.height)]
    labels = [f'{args.left}  (full height {panes[0][1]} css px)']
    if args.right != '-':
        panes.append(window(args.right, args.top, args.height))
        labels.append(f'{args.right}  (full height {panes[1][1]} css px)')

    ruler = 44
    gap = 16
    head = 28
    width = ruler + len(panes) * WIDTH + (len(panes) - 1) * gap
    sheet = Image.new('RGB', (width, head + args.height * 2), (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    for index, ((pane, _), label) in enumerate(zip(panes, labels)):
        x = ruler + index * (WIDTH + gap)
        sheet.paste(pane, (x, head))
        draw.text((x + 4, 8), label[-110:], fill=(0, 0, 0))
    for css in range(0, args.height + 1, 50):
        y = head + css * 2
        draw.line([(0, y), (ruler - 6, y)], fill=(160, 160, 160))
        draw.text((2, y + 2), str(args.top + css), fill=(90, 90, 90))
    sheet.save(args.out)
    print(args.out, sheet.size)


if __name__ == '__main__':
    main()
