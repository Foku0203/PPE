"""Debug helper: opens the language menu on the login page and dumps a screenshot + semantics labels."""
import os, time
from playwright.sync_api import sync_playwright

OUT = r"D:\PPE\showcase\shots"
with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(r"D:\PPE\showcase\.chrome-profile", channel="chrome", headless=True,
                                               viewport={"width": 390, "height": 844}, device_scale_factor=2)
    page = ctx.pages[0]
    page.goto("http://127.0.0.1:8080/#/login")
    time.sleep(6)
    page.evaluate("() => document.querySelector('flt-semantics-placeholder')?.click()")
    time.sleep(1)
    page.screenshot(path=os.path.join(OUT, "_probe_menu.png"))
    print(page.evaluate("() => Array.from(document.querySelectorAll('flt-semantics')).map(e => (e.getAttribute('role')||'') + ':' + (e.getAttribute('aria-label')||e.textContent||'').trim()).filter(s => s.length > 1).slice(0, 60)"))
    ctx.close()
