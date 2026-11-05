"""Procedural old-pixel-art textures for RadioÚstí (deterministic, seeded by name)."""
import hashlib
import numpy as np
from PIL import Image


def hexc(h, a=255):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(ch * 2 for ch in h)
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def rng(name):
    return np.random.default_rng(int(hashlib.md5(name.encode()).hexdigest()[:8], 16))


class Tex:
    def __init__(self, name, size=16, base="#808080", alpha=255):
        self.n = size
        self.r = rng(name)
        self.a = np.zeros((size, size, 4), dtype=np.int32)
        self.a[:, :] = hexc(base, alpha)

    # --- primitives
    def noise(self, amt=14, mono=True):
        n = self.n
        if mono:
            d = self.r.integers(-amt, amt + 1, (n, n, 1))
            self.a[:, :, :3] += d
        else:
            self.a[:, :, :3] += self.r.integers(-amt, amt + 1, (n, n, 3))
        return self

    def px(self, x, y, c, a=255):
        if 0 <= x < self.n and 0 <= y < self.n:
            self.a[y, x] = hexc(c, a)
        return self

    def rect(self, x, y, w, h, c, a=255):
        self.a[max(0, y):y + h, max(0, x):x + w] = hexc(c, a)
        return self

    def frame(self, c, t=1, a=255):
        n = self.n
        self.rect(0, 0, n, t, c, a); self.rect(0, n - t, n, t, c, a)
        self.rect(0, 0, t, n, c, a); self.rect(n - t, 0, t, n, c, a)
        return self

    def shade(self, x, y, w, h, d):
        self.a[y:y + h, x:x + w, :3] += d
        return self

    def speckle(self, colors, count):
        for _ in range(count):
            x, y = self.r.integers(0, self.n, 2)
            c = colors[self.r.integers(0, len(colors))]
            self.px(int(x), int(y), c)
        return self

    def blobs(self, colors, count, size=2):
        for _ in range(count):
            x, y = self.r.integers(0, self.n - size + 1, 2)
            c = colors[self.r.integers(0, len(colors))]
            self.rect(int(x), int(y), size, size, c)
            self.px(int(x) + size, int(y) + 1, c)
        return self

    def hline(self, y, c, a=255):
        return self.rect(0, y, self.n, 1, c, a)

    def vline(self, x, c, a=255):
        return self.rect(x, 0, 1, self.n, c, a)

    def bricks(self, brick, mortar, h=4, w=8, var=18):
        n = self.n
        self.a[:, :] = hexc(mortar)
        for row in range(0, n, h):
            off = (w // 2) if (row // h) % 2 else 0
            for col in range(-w, n + w, w):
                x0 = col + off
                c = np.array(hexc(brick))
                c[:3] += self.r.integers(-var, var + 1)
                for yy in range(row, min(row + h - 1, n)):
                    for xx in range(x0, x0 + w - 1):
                        if 0 <= xx < n:
                            self.a[yy, xx] = c
        return self

    def stripes(self, c1, c2, w=4):
        n = self.n
        for y in range(n):
            for x in range(n):
                self.a[y, x] = hexc(c1 if ((x + y) // w) % 2 == 0 else c2)
        return self

    def rivets(self, c, inset=2):
        n = self.n
        for x, y in ((inset, inset), (n - 1 - inset, inset), (inset, n - 1 - inset), (n - 1 - inset, n - 1 - inset)):
            self.px(x, y, c)
        return self

    def text(self, s, x, y, c, scale=1):
        for ch in s:
            g = FONT.get(ch.upper())
            if g is None:
                x += 4 * scale
                continue
            for gy, row in enumerate(g):
                for gx, bit in enumerate(row):
                    if bit == "1":
                        self.rect(x + gx * scale, y + gy * scale, scale, scale, c)
            x += (len(g[0]) + 1) * scale
        return self

    def save(self, path):
        a = np.clip(self.a, 0, 255).astype(np.uint8)
        Image.fromarray(a, "RGBA").save(path)


FONT = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
    "C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"], "J": ["001", "001", "001", "101", "010"],
    "K": ["101", "110", "100", "110", "101"], "L": ["100", "100", "100", "100", "111"],
    "M": ["10001", "11011", "10101", "10001", "10001"], "N": ["1001", "1101", "1011", "1001", "1001"],
    "O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
    "R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"],
    "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"], "W": ["10001", "10001", "10101", "11011", "10001"],
    "X": ["101", "101", "010", "101", "101"], "Y": ["101", "101", "010", "010", "010"],
    "Z": ["111", "001", "010", "100", "111"], "Ú": ["010", "101", "101", "101", "111"],
    "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
    "2": ["110", "001", "010", "100", "111"], "7": ["111", "001", "010", "010", "010"],
    "3": ["111", "001", "011", "001", "111"], "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "110", "001", "110"], "6": ["011", "100", "111", "101", "111"],
    "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "110"],
    "Í": ["111", "010", "010", "010", "111"],
    "!": ["1", "1", "1", "0", "1"], "-": ["000", "000", "111", "000", "000"],
}

# ------------------------------------------------------------------ palette
P = {
    "concrete": "#8d8a82", "concrete_d": "#6f6c65", "yellow_cement": "#c7b26a", "brick": "#8e4b35",
    "brick_old": "#7a4a3a", "mortar": "#a59d8c", "steel": "#7c848a", "steel_d": "#4b5257", "steel_l": "#a9b1b6",
    "rust": "#8b4a24", "panel_green": "#5e6f55", "panel_beige": "#c9bfa4", "crt": "#1c2a22",
    "screen_on": "#2f6d9e", "screen_ui": "#d9e8f5", "longhorn": "#3b7bbf", "uranium": "#5fd14a",
    "glow_warm": "#ffe29a", "glow_cold": "#e6f4ff", "glow_red": "#ff4a3a", "glow_orange": "#ffa21a",
    "blood": "#7a0e12", "blood_d": "#4a070a", "flesh": "#b25a5a", "flesh_d": "#7d3434", "soul": "#5ae3e6",
    "wood": "#8a6a43", "wood_d": "#5e4528", "paper": "#e8e0c8", "ink": "#2b2b2b", "fabric_w": "#dfe3e3",
    "fabric_b": "#5f8db0", "grass_c": "#7b8a3a", "dirt_c": "#6b5a3a", "stone": "#7f7f7f",
    "fort": "#8a8478", "hazard": "#e0a800", "black": "#1d1d1d",
}


def concrete(name, base=P["concrete"], cracks=True):
    t = Tex(name, base=base).noise(10)
    t.speckle(["#5f5c56", "#a19d95"], 12)
    if cracks:
        x, y = t.r.integers(2, 12, 2)
        for i in range(6):
            t.px(int(x) + i, int(y) + (i % 3) - 1, "#55524d")
    return t


def metal(name, base=P["steel"], rust=0, rivet=True):
    t = Tex(name, base=base).noise(6)
    t.frame("#3c4246")
    t.shade(1, 1, 14, 1, 25)
    if rivet:
        t.rivets("#c0c7cc")
    if rust:
        t.blobs([P["rust"], "#6e3a1d"], rust, 1)
    return t


def screen(name, kind):
    t = Tex(name, base="#0f1512")
    if kind == "off":
        t.noise(4)
        t.rect(2, 2, 3, 1, "#26332c")
        return t
    if kind == "longhorn":
        # Longhorn-inspired: blue-glass desktop, sidebar, taskbar (no logos)
        t = Tex(name, base="#2c5d93")
        for y in range(16):
            t.rect(0, y, 16, 1, "#%02x%02x%02x" % (30 + y * 3, 80 + y * 4, 140 + y * 4))
        t.rect(11, 1, 4, 12, "#cfe1f3", 200)
        t.rect(12, 2, 2, 1, "#4a86c5"); t.rect(12, 4, 2, 1, "#4a86c5"); t.rect(12, 6, 2, 1, "#6fc35a")
        t.rect(0, 13, 16, 3, "#1b2d44")
        t.rect(1, 14, 2, 1, "#8fd16b")
        t.rect(2, 3, 2, 2, "#f2e6a0"); t.rect(2, 7, 2, 2, "#f2e6a0"); t.rect(6, 3, 2, 2, "#e0eef8")
        return t
    if kind == "terminal":
        t.noise(3)
        for y in (2, 4, 6, 8, 10):
            w = int(t.r.integers(4, 12))
            t.rect(2, y, w, 1, "#5ee08a")
        t.rect(2, 12, 2, 1, "#a8ffbf")
        return t
    if kind == "leds":
        t = Tex(name, base="#202326")
        for y in range(1, 16, 3):
            t.rect(1, y, 14, 2, "#2e3236")
            for x in (2, 4, 6):
                t.px(x, y, ["#3df25a", "#f2c23d", "#3df25a"][int(t.r.integers(0, 3))])
            t.rect(9, y, 5, 1, "#15181a")
        return t
    if kind == "gauge":
        t = Tex(name, base="#e8e3cf").frame("#2b2b2b")
        t.rect(3, 9, 10, 2, "#2b2b2b"); t.rect(4, 4, 1, 5, "#c23b22"); t.px(5, 4, "#c23b22")
        return t
    if kind == "medical":
        t.noise(2)
        pts = [10, 10, 10, 9, 4, 13, 10, 10, 10, 10, 8, 11, 10, 10, 10, 10]
        for x, y in enumerate(pts):
            t.px(x, y, "#4dff7a")
        t.text("72", 2, 2, "#4dff7a")
        return t
    if kind == "dial":
        t = Tex(name, base="#dcd6be").frame("#222")
        t.rect(2, 3, 4, 2, "#3aa63a"); t.rect(6, 3, 4, 2, "#e0a800"); t.rect(10, 3, 4, 2, "#c23b22")
        t.rect(7, 6, 1, 6, "#222"); t.text("R", 2, 9, "#222")
        return t
    if kind == "clock":
        t = Tex(name, base="#efe9d6").frame("#3a2c1c")
        for x, y in ((7, 1), (14, 7), (7, 14), (1, 7)):
            t.px(x, y, "#222")
        t.rect(7, 4, 1, 4, "#222"); t.rect(7, 7, 4, 1, "#222")
        return t
    if kind == "fan":
        t = Tex(name, base="#3a3f43").frame("#222")
        for i in range(2, 14, 2):
            t.hline(i, "#25292c")
        t.rect(6, 6, 4, 4, "#7c848a")
        return t
    raise ValueError(kind)


def glow(name, c):
    t = Tex(name, base=c).noise(6)
    t.frame("#ffffff", a=120) if False else None
    return t


def wood(name, base=P["wood"]):
    t = Tex(name, base=base)
    for y in range(0, 16, 4):
        t.hline(y, P["wood_d"])
        t.shade(0, y + 1, 16, 1, 12)
    t.noise(8)
    return t


def paper(name, kind=0):
    t = Tex(name, base=P["paper"], alpha=255).noise(5)
    t.frame("#bdb49a")
    if kind == 0:
        for y in range(3, 14, 2):
            t.rect(2, y, int(t.r.integers(7, 12)), 1, "#6b6656")
    elif kind == 1:
        t.rect(2, 2, 12, 3, "#9d2a22"); t.text("RU", 4, 2, "#fff")
        for y in range(7, 14, 2):
            t.rect(2, y, 11, 1, "#6b6656")
    elif kind == 2:
        for y in range(1, 15, 2):
            t.rect(1, y, 14, 1, "#dfe9e0")
            t.rect(2, y, int(t.r.integers(4, 12)), 1, "#3b4a3d")
        t.vline(0, "#9aa59b")
    else:
        t.rect(2, 2, 6, 5, "#77705e"); t.rect(9, 3, 5, 1, "#6b6656"); t.rect(9, 5, 4, 1, "#6b6656")
        for y in range(9, 14, 2):
            t.rect(2, y, 12, 1, "#6b6656")
        t.rect(10, 11, 4, 3, "#a3321f", 180)
    return t


def poster(name, kind):
    t = Tex(name, size=32, base="#d9cfb3").noise(6)
    t.frame("#3a352b")
    if kind == "outbreak":
        t.rect(2, 2, 28, 10, "#8f1d18"); t.text("2072", 6, 4, "#f1e9d2", 1); t.text("ZED", 19, 4, "#f1e9d2")
        for i in range(5):
            t.rect(6 + i * 4, 16 + (i % 2) * 2, 3, 8, "#2a2a2a")
            t.rect(6 + i * 4, 14 + (i % 2) * 2, 3, 2, "#5e6f55")
        t.text("ÚSTÍ", 8, 26, "#2a2a2a")
    elif kind == "evacuation":
        t.rect(2, 2, 28, 7, "#e0a800"); t.text("EVAKUACE", 2, 3, "#1d1d1d")
        t.rect(6, 12, 20, 12, "#40506a")
        for x in range(8, 24, 4):
            t.rect(x, 14, 2, 3, "#d9cfb3")
        t.rect(14, 26, 4, 3, "#1d1d1d"); t.rect(10, 26, 12, 1, "#1d1d1d")
    elif kind == "radiation":
        t.rect(0, 0, 32, 32, "#e0a800"); t.frame("#1d1d1d", 2)
        t.rect(14, 14, 4, 4, "#1d1d1d")
        for dx, dy in ((0, -1), (-1, 1), (1, 1)):
            t.rect(14 + dx * 7, 14 + dy * 6, 5, 5, "#1d1d1d")
        t.text("2072", 9, 25, "#1d1d1d")
    elif kind == "zedsworld":
        t.rect(2, 2, 28, 28, "#1f2a22")
        t.rect(10, 6, 12, 12, "#8aa37a"); t.rect(12, 9, 3, 3, "#1a0505"); t.rect(17, 9, 3, 3, "#1a0505")
        t.rect(13, 14, 6, 2, "#4a070a"); t.text("ZEDS", 8, 22, "#c9d6b8")
    elif kind == "collapse":
        t.rect(2, 2, 28, 18, "#5a6470")
        for x in range(3, 29, 5):
            h = int(t.r.integers(5, 14))
            t.rect(x, 20 - h, 4, h, "#2c3036")
        t.rect(2, 20, 28, 2, "#7a0e12"); t.text("KONEC", 6, 24, "#2a2a2a")
    elif kind == "fortress":
        t.rect(2, 2, 28, 28, "#6b8bb0")
        t.rect(4, 14, 24, 14, "#8a8478")
        for x in range(4, 28, 4):
            t.rect(x, 11, 2, 3, "#8a8478")
        t.rect(14, 20, 4, 8, "#3a2c1c"); t.text("1472", 9, 4, "#f1e9d2")
    return t


def ore(name, base_stone, speck):
    t = Tex(name, base=base_stone).noise(14)
    t.blobs([speck, "#9dff7a", "#3aa03a"], 6, 2)
    return t


def contaminated(name, kind):
    if kind == "grass_top":
        t = Tex(name, base="#6f7d2f").noise(16)
        t.speckle(["#a9c23a", "#4b5a1f", "#c4d94a"], 30)
        return t
    if kind == "grass_side":
        t = Tex(name, base=P["dirt_c"]).noise(12)
        t.rect(0, 0, 16, 4, "#6f7d2f")
        for x in range(16):
            if t.r.random() < 0.5:
                t.px(x, 4, "#6f7d2f")
        t.speckle(["#a9c23a"], 6)
        return t
    if kind == "dirt":
        t = Tex(name, base="#5e5134").noise(14)
        t.speckle(["#8fa83a", "#3d3622", "#b0c24a"], 18)
        return t
    if kind == "stone":
        t = Tex(name, base="#6f7468").noise(14)
        t.speckle(["#9dbb4a", "#4a5a3a"], 14)
        return t
    if kind == "waste":
        t = Tex(name, base="#3b4a1f").noise(18)
        t.blobs(["#7dff3a", "#b8ff5a", "#2a3a10"], 9, 2)
        return t
    raise ValueError(kind)


def flesh(name, kind=0):
    t = Tex(name, base=P["flesh"]).noise(16)
    t.blobs([P["flesh_d"], "#c97a7a"], 8, 2)
    if kind == 1:
        for _ in range(3):
            x, y = t.r.integers(1, 14, 2)
            for i in range(5):
                t.px(int(x) + i, int(y) + (i % 2), "#5a1a2a")
    if kind == 2:
        t.rect(5, 5, 3, 3, "#efe6d0"); t.px(6, 6, "#1a0a0a")
        t.rect(10, 9, 2, 2, "#efe6d0"); t.px(10, 9, "#1a0a0a")
    return t


def soul(name, kind=0):
    t = Tex(name, base="#2a2338").noise(10)
    t.speckle([P["soul"], "#9ffbff", "#2fb7c2"], 22 if kind == 0 else 40)
    return t


def glass(name, kind="old"):
    t = Tex(name, base="#9fc4c9", alpha=90)
    if kind == "old":  # Czechoslovak glass blocks (luxfer)
        for y in (0, 8):
            for x in (0, 8):
                t.rect(x, y, 8, 8, "#b8d6d9", 130)
                t.rect(x, y, 8, 1, "#6f8a8d"); t.rect(x, y, 1, 8, "#6f8a8d")
                t.rect(x + 2, y + 2, 4, 4, "#d6ecee", 160)
        return t
    if kind == "help":
        t = Tex(name, size=32, base="#9fc4c9", alpha=70)
        t.frame("#5a6a6c", 2)
        t.text("HELP", 4, 10, "#b3170f", 2)
        t.text("!", 27, 10, "#b3170f", 2)
        t.rect(3, 23, 26, 1, "#b3170f", 200)
        return t
    if kind == "reactor":
        t = Tex(name, base="#5dd6c9", alpha=110)
        t.frame("#3c4246", 2)
        t.rect(7, 2, 2, 12, "#3c4246"); t.rect(2, 7, 12, 2, "#3c4246")
        return t
    raise ValueError(kind)


def item_canvas(name):
    return Tex(name, base="#000000", alpha=0)


def item(name, kind, color="#888888"):
    t = item_canvas(name)
    o = "#1d1d1d"
    if kind == "bottle":
        t.rect(6, 1, 4, 2, "#8a6a43"); t.rect(6, 3, 4, 3, "#bfe0e8", 160)
        t.rect(4, 6, 8, 9, "#bfe0e8", 140); t.rect(5, 8, 6, 6, color); t.rect(4, 15, 8, 1, o)
    elif kind == "jar":
        t.rect(4, 2, 8, 2, "#6f6c65"); t.rect(3, 4, 10, 11, "#c9e6ec", 120)
        if color:
            t.rect(4, 7, 8, 7, color)
        t.rect(3, 15, 10, 1, o)
    elif kind == "tube":
        t.rect(7, 1, 3, 1, "#6f6c65"); t.rect(7, 2, 3, 12, "#d6eef2", 130)
        if color:
            t.rect(7, 8, 3, 5, color)
        t.rect(8, 14, 1, 1, "#d6eef2", 130)
    elif kind == "flask":
        t.rect(7, 1, 2, 5, "#d6eef2", 150); t.rect(5, 6, 6, 2, "#d6eef2", 150); t.rect(3, 8, 10, 6, "#d6eef2", 150)
        if color:
            t.rect(4, 10, 8, 4, color)
        t.rect(3, 14, 10, 1, o)
    elif kind == "container":
        t.rect(3, 4, 10, 10, "#e4e4dc"); t.rect(3, 3, 10, 2, color); t.rect(6, 8, 4, 2, "#b3170f")
        t.rect(3, 14, 10, 1, o)
    elif kind == "canister":
        t.rect(3, 4, 10, 11, color); t.rect(9, 1, 3, 3, "#3c4246"); t.rect(4, 2, 4, 2, "#3c4246")
        t.rect(5, 7, 6, 4, "#e8e0c8"); t.rect(6, 8, 4, 2, "#1d1d1d"); t.rect(3, 15, 10, 1, o)
    elif kind == "gascan":
        t.rect(5, 3, 6, 12, color); t.rect(6, 1, 4, 2, "#3c4246"); t.rect(5, 7, 6, 1, "#e0a800"); t.rect(5, 15, 6, 1, o)
    elif kind == "ingot":
        t.rect(2, 7, 12, 4, color); t.rect(3, 6, 10, 1, "#c8ffb0"); t.rect(2, 11, 12, 1, "#2a6a20")
    elif kind == "raw":
        t.rect(4, 5, 8, 7, color); t.rect(3, 7, 2, 4, color); t.rect(11, 6, 2, 4, color)
        t.speckle(["#2a6a20", "#c8ffb0"], 8)
    elif kind == "rod":
        t.rect(7, 1, 2, 14, "#7c848a"); t.rect(6, 3, 4, 10, color); t.rect(6, 1, 4, 1, "#3c4246"); t.rect(6, 14, 4, 1, "#3c4246")
    elif kind == "pickaxe":
        for i in range(10):
            t.px(4 + i, 13 - i, "#5e4528"); t.px(5 + i, 13 - i, "#8a6a43")
        t.rect(2, 2, 6, 2, color); t.rect(8, 3, 4, 2, color); t.rect(11, 5, 2, 5, color); t.rect(1, 4, 2, 2, color)
        t.px(12, 10, "#c0c7cc")
    elif kind == "scanner":
        t.rect(4, 2, 8, 12, "#e0a800"); t.rect(5, 3, 6, 5, "#1c2a22"); t.rect(6, 4, 4, 1, "#5ee08a")
        t.rect(6, 6, 3, 1, "#5ee08a"); t.rect(5, 9, 2, 2, "#b3170f"); t.rect(9, 9, 2, 2, "#3c4246")
        t.rect(7, 0, 2, 2, "#3c4246"); t.rect(5, 12, 6, 1, "#3c4246")
    elif kind == "book":
        t.rect(3, 2, 10, 12, color); t.rect(3, 2, 2, 12, "#3b2a1a"); t.rect(12, 3, 1, 10, "#e8e0c8")
        t.rect(6, 5, 5, 3, "#e0a800"); t.px(8, 6, "#1d1d1d")
    elif kind == "doc":
        t.rect(3, 1, 10, 14, P["paper"]); t.rect(3, 1, 10, 1, "#bdb49a")
        for y in range(4, 13, 2):
            t.rect(5, y, 6, 1, "#6b6656")
        t.rect(9, 11, 3, 3, color, 220)
    elif kind == "bundle":
        t.rect(2, 4, 12, 9, "#cfc6ac"); t.rect(3, 3, 11, 9, P["paper"]); t.rect(2, 7, 12, 1, color)
        t.rect(7, 3, 1, 10, color)
    elif kind == "photo":
        t.rect(2, 3, 12, 10, "#f0ece0"); t.rect(3, 4, 10, 7, "#7a7465"); t.rect(4, 7, 3, 4, "#4c473d")
        t.rect(9, 5, 3, 6, "#5c574c")
    elif kind == "pills":
        t.rect(5, 2, 6, 2, "#e8e8e8"); t.rect(5, 4, 6, 10, color); t.rect(6, 7, 4, 3, "#ffffff")
    elif kind == "serum":
        t.rect(7, 0, 2, 3, "#3c4246"); t.rect(6, 3, 4, 10, "#d6eef2", 150); t.rect(7, 5, 2, 7, color)
        t.rect(7, 13, 2, 2, "#7c848a")
    elif kind == "kit":
        t.rect(2, 4, 12, 10, "#e6e6e6"); t.rect(6, 2, 4, 2, "#3c4246"); t.rect(7, 6, 2, 6, color); t.rect(5, 8, 6, 2, color)
    elif kind == "mask":
        t.rect(4, 3, 8, 8, "#3c4246"); t.rect(5, 5, 2, 2, "#9fc4c9"); t.rect(9, 5, 2, 2, "#9fc4c9")
        t.rect(6, 11, 4, 4, "#5e6f55"); t.rect(7, 12, 2, 2, "#1d1d1d")
    elif kind == "suit":
        t.rect(4, 2, 8, 10, color); t.rect(2, 3, 2, 7, color); t.rect(12, 3, 2, 7, color)
        t.rect(5, 12, 2, 3, color); t.rect(9, 12, 2, 3, color); t.rect(6, 4, 4, 2, "#1d1d1d")
    elif kind == "chunk":
        t.rect(3, 5, 10, 7, color); t.rect(5, 4, 6, 1, color); t.speckle(["#5a1a2a", "#c97a7a"], 10)
    elif kind == "meat":
        t.rect(3, 6, 9, 6, color); t.rect(11, 8, 3, 2, "#efe6d0"); t.rect(4, 7, 3, 2, "#c97a7a")
    elif kind == "essence":
        t.rect(6, 3, 4, 10, color); t.rect(4, 6, 8, 4, color); t.px(7, 5, "#ffffff"); t.speckle(["#9ffbff"], 4)
    elif kind == "waste":
        t.rect(4, 4, 8, 10, "#5e6f55"); t.rect(4, 3, 8, 1, "#3c4246"); t.rect(6, 7, 4, 4, "#e0a800"); t.px(7, 8, "#1d1d1d")
    elif kind == "vhs":
        t.rect(1, 4, 14, 9, "#1d1d1d"); t.rect(3, 5, 10, 4, "#d9cfb3"); t.rect(4, 6, 3, 2, "#3a3a3a"); t.rect(9, 6, 3, 2, "#3a3a3a")
        t.rect(3, 10, 10, 2, "#2c2c2c"); t.rect(4, 5, 8, 1, color)
    elif kind == "block_icon":
        t.rect(2, 4, 12, 10, color); t.rect(3, 2, 10, 2, "#3c4246"); t.rect(4, 7, 8, 3, "#1c2a22"); t.rect(5, 8, 2, 1, "#5ee08a")
    elif kind == "door_icon":
        t.rect(4, 1, 8, 14, color); t.rect(5, 2, 6, 5, "#9fc4c9", 200); t.rect(10, 8, 1, 2, "#e0a800")
    elif kind == "bed_icon":
        t.rect(1, 7, 14, 4, "#dfe3e3"); t.rect(1, 11, 14, 1, "#7c848a"); t.rect(1, 4, 2, 9, "#7c848a"); t.rect(3, 6, 3, 2, "#ffffff")
    elif kind == "gen_icon":
        t.rect(1, 4, 14, 10, color); t.rect(2, 6, 7, 4, "#1c2a22"); t.rect(3, 7, 3, 1, "#5ee08a"); t.rect(11, 2, 3, 3, "#3c4246")
        t.rect(10, 7, 3, 3, "#e0a800"); t.rect(1, 14, 14, 1, "#1d1d1d")
    else:
        raise ValueError(kind)
    return t


def armor_layer(name, kind):
    t = Tex(name, size=64, base="#000000", alpha=0)
    t.a = np.zeros((32, 64, 4), dtype=np.int32)
    t.n = 64

    def r(x, y, w, h, c, a=255):
        t.a[y:y + h, x:x + w] = hexc(c, a)
    if kind == "mask":
        # helmet region: head box 8x8x8 at uv (0,0) -> faces in 32x16 area
        r(0, 8, 32, 8, "#3c4246")
        r(8, 0, 16, 8, "#3c4246")
        r(9, 10, 2, 2, "#9fc4c9"); r(13, 10, 2, 2, "#9fc4c9"); r(10, 13, 4, 3, "#5e6f55")
    else:
        r(16, 16, 24, 16, "#d4b62a")   # body
        r(40, 16, 16, 16, "#d4b62a")   # arms
        r(20, 20, 8, 2, "#1d1d1d")
    return t
