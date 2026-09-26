"""Resizes the source artwork in D:/PPE/image for the showcase page and the Flutter app."""
import os
from PIL import Image

SRC = r"D:\PPE\image"
WEB = r"D:\PPE\showcase\assets"
APP = r"D:\PPE\ppe_mobile_app\assets\images"
os.makedirs(WEB, exist_ok=True)

logo = Image.open(os.path.join(SRC, "6E53C440-218B-4B7E-A8EA-310992018762.png")).convert("RGBA")
w, h = logo.size


def whiten_to_alpha(img):
    """Turns the near-white background transparent so the mark sits on any colour."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            m = min(r, g, b)
            if m > 235:
                px[x, y] = (r, g, b, int(a * (255 - m) / 20))
    return img


full = whiten_to_alpha(logo.resize((720, int(720 * h / w)), Image.LANCZOS))
full.save(os.path.join(WEB, "logo-full.png"), optimize=True)

# Shield mark only (without the wordmark) for app bars, favicon and the Flutter app.
mark = logo.crop((int(w * 0.24), int(h * 0.075), int(w * 0.76), int(h * 0.705)))
mark = whiten_to_alpha(mark.resize((512, int(512 * mark.height / mark.width)), Image.LANCZOS))
mark.save(os.path.join(WEB, "logo-mark.png"), optimize=True)
mark.resize((256, int(256 * mark.height / mark.width)), Image.LANCZOS).save(os.path.join(APP, "logo_mark.png"), optimize=True)
fav = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
small = mark.resize((int(192 * mark.width / mark.height), 192), Image.LANCZOS)
fav.paste(small, ((192 - small.width) // 2, 0), small)
fav.save(os.path.join(WEB, "favicon.png"))

for name, out, size in [("ปกแอพ.png", "cover-construction.jpg", 1400),
                        ("ไอคอนลอยโชว์สวยๆ.png", "poster-ppe.jpg", 1100),
                        ("ไอคอนลอยดชว์.jpg", "poster-fire.jpg", 900)]:
    im = Image.open(os.path.join(SRC, name)).convert("RGB")
    im.thumbnail((size, size), Image.LANCZOS)
    im.save(os.path.join(WEB, out), quality=84, optimize=True, progressive=True)

for f in sorted(os.listdir(WEB)):
    print(f, os.path.getsize(os.path.join(WEB, f)) // 1024, "KB")
