import sys
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
raw = "data/raw/background/"; out = "docs/m1.4a/"
src = {"noirlab": "noirlab_10k.tif", "eso": "eso0932a_large.jpg", "gaia": "gaia_edr3_16k.png"}
# galactic equirect, l=0 centre, l increases to the left; regions as (name, l_centre, b_centre, half-width deg, half-height deg)
regions = [("galactic_centre", 0, 0, 20, 10), ("crux_carina", 295, -1, 20, 10), ("orion", 205, -16, 20, 10)]
for k, f in src.items():
    im = Image.open(raw + f).convert("RGB"); W, H = im.size
    full = im.resize((2400, 1200), Image.LANCZOS); full.save(out + f"{k}_full.jpg", quality=88)
    for name, l, b, hw, hh in regions:
        x0 = 0.5 - ((l + 180) % 360 - 180) / 360
        cx, cy = x0 * W, (0.5 - b / 180) * H
        box = (int(cx - hw / 360 * W), int(cy - hh / 180 * H), int(cx + hw / 360 * W), int(cy + hh / 180 * H))
        im.crop(box).resize((1600, 800), Image.LANCZOS).save(out + f"{k}_{name}.jpg", quality=90)
    print(k, W, H)
