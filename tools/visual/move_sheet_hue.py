"""Offline HSV hue rotation of effect sheets only; no geometry/resampling.

Semantics checked against Essentials BattleAnimationPlayer (animation.hue only
on animbitmap) and mkxp Bitmap::hueChange / shader/hue.frag (positive HSV turn,
integer degrees modulo 360). This uses Python colorsys, not copied shader code.
One-byte RGB rounding differences from a GPU are possible; alpha is exact.
"""
import colorsys
from functools import lru_cache
from PIL import Image


def normalize_hue(value):
    # RGSS hueChange takes integer degrees. Reject malformed input, don't guess.
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError("invalid_sheet_hue")
    return value % 360


def rotate_sheet(image, degrees):
    degrees = normalize_hue(degrees)
    rgba = image.convert("RGBA")
    if not degrees:
        return rgba.copy()

    @lru_cache(maxsize=65536)
    def recolor(r, g, b):
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        rgb = colorsys.hsv_to_rgb((h + degrees / 360) % 1, s, v)
        return bytes(min(255, max(0, int(c * 255 + 0.5))) for c in rgb)

    pixels = bytearray(rgba.tobytes())
    for offset in range(0, len(pixels), 4):
        pixels[offset:offset + 3] = recolor(*pixels[offset:offset + 3])
    return Image.frombytes("RGBA", rgba.size, bytes(pixels))
