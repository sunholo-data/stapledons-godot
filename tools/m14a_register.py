"""M1.4a spike: measure where catalogue bright stars land on the NOIRLab panorama."""
import numpy as np
from PIL import Image
Image.MAX_IMAGE_PIXELS = None

def load_hip(path="data/raw/hip_v7.tsv"):
    rows = []
    for line in open(path):
        p = line.rstrip("\n").split("\t")
        if len(p) < 6 or not p[0].strip().isdigit() or not (p[1].strip() and p[2].strip() and p[3].strip()):
            continue
        rows.append((int(p[0]), float(p[1]), float(p[2]), float(p[3])))
    return np.array(rows)  # hip, V, l, b

def lb_to_px(l, b, W, H):
    lw = (np.asarray(l) + 180.0) % 360.0 - 180.0
    return (0.5 - lw / 360.0) * W, (0.5 - np.asarray(b) / 180.0) * H

if __name__ == "__main__":
    im = np.asarray(Image.open("data/raw/background/noirlab_10k.tif").convert("L"), dtype=np.float32)
    H, W = im.shape
    hip = load_hip(); hip = hip[np.argsort(hip[:, 1])]
    hip = hip[np.abs(hip[:, 3]) < 75][:80]
    R = 40; out = []
    for h, v, l, b in hip:
        px, py = lb_to_px(l, b, W, H)
        x0, y0 = int(px) - R, int(py) - R
        if y0 < 0 or y0 + 2 * R >= H: continue
        xs = (np.arange(x0, x0 + 2 * R + 1)) % W
        win = im[y0:y0 + 2 * R + 1][:, xs]
        w = np.clip(win - np.percentile(win, 90), 0, None) ** 2
        yy, xx = np.mgrid[0:w.shape[0], 0:w.shape[1]]
        cx, cy = (w * xx).sum() / w.sum() + x0, (w * yy).sum() / w.sum() + y0
        out.append((h, v, l, b, cx - px, cy - py))
    o = np.array(out)
    np.set_printoptions(suppress=True, precision=2, linewidth=140)
    print("hip V l b dx dy"); print(o[:25])
    print("median dx dy", np.median(o[:, 4]), np.median(o[:, 5]), "MAD", np.median(np.abs(o[:, 4] - np.median(o[:, 4]))), np.median(np.abs(o[:, 5] - np.median(o[:, 5]))))
    np.save("/private/tmp/claude-501/-Users-voightkampff-dev-sunholo-data-stapledons-godot/cc024122-aa3b-4d58-84e7-3217521e506a/scratchpad/reg.npy", o)
