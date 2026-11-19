"""Draws the white shape textures in FoilKeybinds/Media (tinted in game with SetVertexColor).

Run from the repo root: python tools/make_media.py
Every pixel is white; only alpha changes, so filtering never adds dark fringes.
All shapes are symmetric top to bottom, so TGA row order cannot flip them.
"""
from PIL import Image, ImageDraw

OUT = "FoilKeybinds/Media/"
SS = 8  # supersampling for smooth edges


def save(mask, name):
    img = Image.new("RGBA", mask.size, (255, 255, 255, 0))
    img.putalpha(mask)
    img.save(OUT + name, compression=None)  # uncompressed 32-bit TGA


def shape(w, h, draw):
    big = Image.new("L", (w * SS, h * SS), 0)
    draw(ImageDraw.Draw(big), SS)
    return big.resize((w, h), Image.LANCZOS)


# Rounded box, 32x32, corner radius 8: sliced with 8 px margins in game.
save(shape(32, 32, lambda d, s: d.rounded_rectangle([0, 0, 32 * s - 1, 32 * s - 1], 8 * s, fill=255)), "Round.tga")

# Circle for the modifier dots.
save(shape(16, 16, lambda d, s: d.ellipse([s, s, 15 * s - 1, 15 * s - 1], fill=255)), "Dot.tga")

# Mouse body: a capsule, stretched to the mouse frame.
save(shape(128, 256, lambda d, s: d.rounded_rectangle([0, 0, 128 * s - 1, 256 * s - 1], 60 * s, fill=255)), "Mouse.tga")


# Dashed rounded outline, 32x32, 2 px line, radius 8. Edges are tiled in game (slice mode Tiled),
# so the 16 px between the corners hold exactly two dashes of 4 px on, 4 px off.
def dash(d, s):
    w = 32 * s
    d.rounded_rectangle([0, 0, w - 1, w - 1], 8 * s, outline=255, width=2 * s)
    for a in (10, 18):  # gaps along each edge, inside the 8..24 edge span
        g = [a * s, (a + 4) * s]
        d.rectangle([g[0], 0, g[1] - 1, 2 * s], fill=0)
        d.rectangle([g[0], w - 2 * s, g[1] - 1, w], fill=0)
        d.rectangle([0, g[0], 2 * s, g[1] - 1], fill=0)
        d.rectangle([w - 2 * s, g[0], w, g[1] - 1], fill=0)


save(shape(32, 32, dash), "Dash.tga")
print("ok")
