"""M1.4a spike (Option A, D-10): remove from the NOIRLab panorama only the point
sources cross-matched to a star in the shipped point layers (CNS5, GCNS, HIP V<7.5).
Unmatched sources stay as panorama pixels, so no star is dropped from both layers
and none is drawn twice. Spike quality: not the M1.4b pipeline.

uv run --with pillow --with numpy --with scipy --with opencv-python-headless \
    python tools/m14a_destar.py
"""
import json
import numpy as np
import cv2
from PIL import Image
from scipy import ndimage as ndi

from m14a_register import load_hip, lb_to_px

Image.MAX_IMAGE_PIXELS = None
RAW = "data/raw/"
OUT = "docs/m1.4a/"
MAX_R = 80          # px cap on a mask radius (Sirius' halo)
POS_TOL = 3.0       # px match radius for faint stars; grows for bright ones
MAG_TOL = 1.5       # mag, |predicted - measured| allowed for a match


def gaia_g_to_v(g, c):
    # Riello et al. 2021, G - V as a cubic in BP-RP (same relation as sunholo/relativity photometry)
    return g - (-0.02704 + 0.01424 * c - 0.2156 * c**2 + 0.01426 * c**3)


def xyz_to_lb(x, y, z):
    r = np.sqrt(x * x + y * y + z * z)
    return np.degrees(np.arctan2(y, x)) % 360.0, np.degrees(np.arcsin(z / r))


def catalogue():
    hip = load_hip(RAW + "hip_v7.tsv")
    g = np.genfromtxt(RAW + "gcns.csv", delimiter=",", names=True)
    gl, gb = xyz_to_lb(g["x"], g["y"], g["z"])
    gv = gaia_g_to_v(g["G"], np.nan_to_num(g["BPRP"], nan=1.0))
    s = json.load(open("data/starmap/stars.json"))["stars"]
    cx = np.array([[t["x"], t["y"], t["z"], t["vmag"]] for t in s if t.get("vmag") is not None and t["dist_ly"] > 0])
    cl, cb = xyz_to_lb(cx[:, 0], cx[:, 1], cx[:, 2])
    l = np.concatenate([hip[:, 2], gl, cl]); b = np.concatenate([hip[:, 3], gb, cb])
    v = np.concatenate([hip[:, 1], gv, cx[:, 3]])
    src = np.concatenate([np.full(len(hip), 0), np.full(len(gl), 1), np.full(len(cl), 2)])
    return l, b, v, src


def detect(lum):
    H, W = lum.shape
    small = cv2.resize(lum, (W // 4, H // 4), interpolation=cv2.INTER_AREA)
    bg = cv2.resize(ndi.percentile_filter(small, 30, size=15, mode="wrap"), (W, H), interpolation=cv2.INTER_LINEAR)
    res = lum - bg
    sigma = 1.4826 * np.median(np.abs(res - np.median(res)))
    peaks = (res == ndi.maximum_filter(res, size=5, mode="wrap")) & (res > 5 * sigma)
    py, px = np.nonzero(peaks)
    flux = ndi.uniform_filter(np.clip(res, 0, None), size=5)[py, px] * 25
    return res, sigma, px.astype(np.float64), py.astype(np.float64), flux


def mask_radius(res, sigma, x, y, peak):
    H, W = res.shape
    for r in range(2, MAX_R + 1):
        ring = []
        for a in np.linspace(0, 2 * np.pi, max(8, int(2 * np.pi * r)), endpoint=False):
            xx, yy = int(round(x + r * np.cos(a))) % W, int(round(y + r * np.sin(a)))
            if 0 <= yy < H:
                ring.append(res[yy, xx])
        if np.median(ring) < max(2 * sigma, 0.03 * peak):
            return r
    return MAX_R


# Median halo radius (px) of isolated matched stars per V bin, measured on this panorama by the
# ring test (2026-10-01 run); the ring test itself grabs nebulosity, so masks use this table.
HALO_V = np.array([-1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5])
HALO_R = np.array([27.0, 26.0, 26.0, 23.0, 20.0, 15.0, 11.0, 6.0, 3.0, 2.0, 2.0])


def halo_radius(vmag):
    return np.interp(vmag, HALO_V, HALO_R) * 1.15 + 1.5


def smooth_fill(img, w):
    """Normalized convolution: background from unmasked pixels only, coarser where holes are big."""
    out = np.zeros_like(img); done = np.zeros(w.shape, bool)
    for s in (3, 8, 20, 50):
        k = int(6 * s) | 1
        num = cv2.GaussianBlur(img * w[..., None], (k, k), s)
        den = cv2.GaussianBlur(w, (k, k), s)
        ok = (den > 0.25) & ~done
        out[ok] = num[ok] / den[ok][:, None]; done |= ok
    return out


def fill(rgb, mask, xs, ys, radii, GRAIN=18.0):
    img = rgb.astype(np.float32); H, W, _ = img.shape
    w = (mask == 0).astype(np.float32)
    base = smooth_fill(img, w)
    # faint-star grain only: masked stars zeroed, clipped so a donor patch can't carry in a whole star
    texture = np.clip(img - smooth_fill(img, np.ones_like(w)), -GRAIN, GRAIN) * w[..., None]
    filled = base.copy()
    for x, y, r in zip(xs, ys, radii):
        R = int(np.ceil(r)) + 2; n = 2 * R + 1
        x0, y0 = int(round(x)) - R, int(round(y)) - R
        if y0 < 0 or y0 + n > H or x0 < 0 or x0 + n > W:
            continue
        best, best_frac = None, 0.2          # nearest donor patch that is at least 80% clean
        for dist in (2.5 * R + 4, 4 * R + 8, 6 * R + 12):
            for ang in np.linspace(0, 2 * np.pi, 16, endpoint=False):
                sx, sy = x0 + int(round(dist * np.cos(ang))), y0 + int(round(dist * np.sin(ang)))
                if 0 <= sy and sy + n <= H and 0 <= sx and sx + n <= W:
                    frac = mask[sy:sy + n, sx:sx + n].mean() / 255
                    if frac < best_frac:
                        best, best_frac = (sx, sy), frac
            if best is not None:
                break
        if best is not None:
            sx, sy = best; ws = w[sy:sy + n, sx:sx + n].mean()
            filled[y0:y0 + n, x0:x0 + n] += texture[sy:sy + n, sx:sx + n] / max(ws, 0.8)  # rescale for the donor's own masked fraction
    a = cv2.GaussianBlur((mask > 0).astype(np.float32), (5, 5), 1.2)[..., None]   # feathered edge
    return np.clip(img * (1 - a) + filled * a, 0, 255).astype(np.uint8)


def main():
    rgb = np.asarray(Image.open(RAW + "background/noirlab_10k.tif").convert("RGB"))
    H, W, _ = rgb.shape
    lum = rgb.astype(np.float32) @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    res, sigma, px, py, flux = detect(lum)
    print(f"detected {len(px)} sources above 5 sigma (sigma={sigma:.2f})")

    l, b, v, src = catalogue()
    cx, cy = lb_to_px(l, b, W, H)
    tree = cv2.flann_Index(np.c_[px, py].astype(np.float32), dict(algorithm=1, trees=4))
    idx, d2 = tree.knnSearch(np.c_[cx, cy].astype(np.float32), 1, params={})
    idx, d = idx[:, 0], np.sqrt(d2[:, 0])

    # zero point from bright, unambiguous matches: m = zp - 2.5 log10(flux)
    tol = POS_TOL + np.clip(4.0 - v, 0, None) * 1.5
    near = d < tol
    m_meas = -2.5 * np.log10(np.maximum(flux[idx], 1e-6))
    sel = near & (v < 6)
    zp = np.median(v[sel] - m_meas[sel])
    dm = np.abs(m_meas + zp - v)
    # saturated stars read faint in a 5x5 box; for them position alone is enough
    match = near & ((dm < MAG_TOL) | (v < 4.5))
    print(f"zp={zp:.2f}; catalogue stars matched: {match.sum()} "
          f"(HIP {np.sum(match & (src == 0))}, GCNS {np.sum(match & (src == 1))}, CNS5 {np.sum(match & (src == 2))})")
    for lo in range(-2, 13):
        inb = (v >= lo) & (v < lo + 1)
        if inb.sum():
            print(f"  V {lo:3d}..{lo+1:3d}: catalogue {inb.sum():6d} matched {np.sum(match & inb):6d}")

    # one entry per panorama source, carrying its brightest matched catalogue magnitude
    order = np.argsort(v[match])
    hit, first = np.unique(idx[match][order], return_index=True)
    vhit = v[match][order][first]
    radii = halo_radius(vhit)
    for k in np.nonzero(vhit < 2.0)[0]:      # brightest halos outgrow the table; few enough that nebulae don't matter
        i = hit[k]
        radii[k] = max(radii[k], 1.25 * mask_radius(res, sigma, px[i], py[i], res[int(py[i]), int(px[i])]) + 2)
    mask = np.zeros((H, W), np.uint8)
    for i, r in zip(hit, radii):
        cv2.circle(mask, (int(round(px[i])), int(round(py[i]))), int(np.ceil(r)), 255, -1)
    print(f"masked {len(hit)} panorama sources; {100 * mask.mean() / 255:.3f}% of pixels")
    unmatched = np.setdiff1d(np.arange(len(px)), hit)
    m_src = -2.5 * np.log10(np.maximum(flux, 1e-6)) + zp
    bright_unmatched = unmatched[m_src[unmatched] < 6.0]
    print(f"unmatched sources kept as pixels: {len(unmatched)} ({len(bright_unmatched)} measure brighter than V~6)")
    clean = fill(rgb, mask, px[hit], py[hit], radii)
    Image.fromarray(clean).save(RAW + "background/noirlab_10k_destarred.png")
    Image.fromarray(mask).save(RAW + "background/noirlab_10k_mask.png")
    np.save(RAW + "background/bright_unmatched.npy", np.c_[px[bright_unmatched], py[bright_unmatched], m_src[bright_unmatched]])

    full = Image.fromarray(clean).resize((2400, 1200), Image.LANCZOS)
    full.save(OUT + "noirlab_destarred_full.jpg", quality=88)
    regions = [("galactic_centre", 0, 0, 20, 10), ("crux_carina", 295, -1, 20, 10), ("orion", 205, -16, 20, 10)]
    over = rgb.copy(); over[mask > 0] = (over[mask > 0] * 0.4 + np.array([0, 255, 0]) * 0.6).astype(np.uint8)
    for name, l0, b0, hw, hh in regions:
        x0, y0 = lb_to_px(l0, b0, W, H)
        box = (int(x0 - hw / 360 * W), int(y0 - hh / 180 * H), int(x0 + hw / 360 * W), int(y0 + hh / 180 * H))
        tiles = [Image.fromarray(a).crop(box).resize((1200, 600), Image.LANCZOS) for a in (rgb, over, clean)]
        sheet = Image.new("RGB", (1200, 1800))
        for k, t in enumerate(tiles):
            sheet.paste(t, (0, 600 * k))
        sheet.save(OUT + f"destar_{name}.jpg", quality=90)


if __name__ == "__main__":
    main()
