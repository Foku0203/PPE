"""Captures every page of the PPE SMART app for every role, at phone size, one folder per role.

Needs: backend on :8000 (python manage.py runserver) and the web build served on :8080
(cd ppe_mobile_app/build/web; python -m http.server 8080). Uses the installed Google Chrome.
Output: D:\\PPE\\screenshots_mobile\\<role>\\NN-<page>.png
Pass page names (e.g. `home`) to re-capture only those pages; numbering stays the same.
"""
import os
import sys
import time

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:8080/#"
OUT = r"D:\PPE\screenshots_mobile"
only = set(sys.argv[1:])

COMMON_TOP = [("home", "/home"), ("catalog", "/catalog"), ("ppe-detail", "/catalog/item/2"),
              ("requests", "/requests"), ("new-request", "/requests/new")]
COMMON_BOTTOM = [("notifications", "/notifications"), ("profile", "/profile"),
                 ("my-ppe", "/profile/my-ppe"), ("sync-queue", "/profile/sync")]
REQUESTS = [("request-pending", "/requests/6"), ("request-rejected", "/requests/5"),
            ("request-ready", "/requests/4"), ("request-completed", "/requests/1")]
STORE = [("store-queue", "/store"), ("inventory", "/inventory"), ("inventory-item", "/inventory/item/10"),
         ("receive-stock", "/inventory/receive"), ("purchase-requests", "/inventory/purchase-requests"),
         ("scan-qr", "/scan")]

ROLES = [
    ("01_worker", "EMP001", COMMON_TOP + REQUESTS + COMMON_BOTTOM),
    ("02_supervisor", "SUP001", COMMON_TOP[:1] + [("approvals", "/approvals")] + COMMON_TOP[1:] + REQUESTS
     + [("analytics", "/analytics")] + COMMON_BOTTOM),
    ("03_store_keeper", "STORE001", COMMON_TOP + REQUESTS + STORE + [("analytics", "/analytics")] + COMMON_BOTTOM),
    ("04_ehs", "EHS001", COMMON_TOP[:1] + [("approvals", "/approvals")] + COMMON_TOP[1:]
     + [("manage-catalog", "/catalog/manage")] + REQUESTS + STORE
     + [("analytics", "/analytics"), ("audit-log", "/admin/audit")] + COMMON_BOTTOM),
    ("05_admin", "ADMIN001", COMMON_TOP[:1] + [("approvals", "/approvals")] + COMMON_TOP[1:]
     + [("manage-catalog", "/catalog/manage")] + REQUESTS + STORE
     + [("analytics", "/analytics"), ("users", "/admin/users"), ("audit-log", "/admin/audit")] + COMMON_BOTTOM),
]


def semantics(page):
    """Flutter web renders to canvas; enabling semantics exposes buttons/text to locators."""
    if page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) { p.click(); return true; } return false; }"):
        time.sleep(0.8)


class Shooter:
    def __init__(self, page, folder):
        self.page, self.dir, self.n = page, os.path.join(OUT, folder), 0
        os.makedirs(self.dir, exist_ok=True)

    def shot(self, name):
        self.n += 1
        if only and name not in only:
            return
        path = os.path.join(self.dir, f"{self.n:02d}-{name}.png")
        self.page.screenshot(path=path)
        print("saved", os.path.relpath(path, OUT))

    def go(self, name, path, wait=4):
        if only and name not in only:
            self.n += 1
            return False
        self.page.goto(f"{BASE}{path}")
        time.sleep(wait)
        landed = self.page.url.split("#", 1)[-1]
        if path != "/home" and landed.rstrip("/").startswith("/home"):
            print("skip", name, "(redirected: role cannot open", path + ")")
            return False
        self.shot(name)
        return True


def logout(page):
    page.evaluate("() => { localStorage.clear(); sessionStorage.clear(); indexedDB.databases && indexedDB.databases().then(d => d.forEach(x => indexedDB.deleteDatabase(x.name))); }")
    time.sleep(1)


def login(page, employee_id):
    page.goto(f"{BASE}/login")
    time.sleep(5)
    semantics(page)
    chip = page.get_by_role("checkbox", name=employee_id, exact=True)
    if chip.count():
        chip.first.click()
    else:
        page.get_by_role("textbox", name="รหัสพนักงาน").first.click()
        page.keyboard.type(employee_id)
        page.get_by_role("textbox", name="รหัสผ่าน").first.click()
        page.keyboard.type("ChangeMe123!")
    time.sleep(0.5)
    page.get_by_role("button", name="เข้าสู่ระบบ").first.click()
    time.sleep(5)


with sync_playwright() as p:
    # Fresh profile with service workers blocked, so the latest web build is always what gets captured.
    browser = p.chromium.launch(channel="chrome", headless=True)
    ctx = browser.new_context(locale="th-TH", service_workers="block",
                              viewport={"width": 390, "height": 844}, device_scale_factor=3, is_mobile=True, has_touch=True)
    page = ctx.new_page()

    # Public pages: login in four languages, register.
    page.goto(f"{BASE}/login")
    time.sleep(6)
    logout(page)
    page.reload()
    time.sleep(6)
    s = Shooter(page, "00_public")
    s.shot("login-th")
    semantics(page)
    for label, name in [("English", "login-en"), ("မြန်မာ", "login-my"), ("中文", "login-zh"), ("ไทย", None)]:
        page.mouse.click(330, 28)  # translate icon in the login app bar
        time.sleep(1.2)
        page.get_by_role("menuitem", name=label).first.click()
        time.sleep(2)
        if name:
            s.shot(name)
    s.go("register", "/register")

    for folder, emp, pages in ROLES:
        login(page, emp)
        s = Shooter(page, folder)
        for name, path in pages:
            captured = s.go(name, path)
            if name == "request-ready" and folder == "01_worker" and not captured:
                s.n += 1  # keep pickup-qr's number when it is filtered out
            elif name == "request-ready" and folder == "01_worker":
                semantics(page)
                btn = page.get_by_role("button", name="แสดง QR รับของ")
                if btn.count():
                    btn.first.click()
                    time.sleep(4)
                    s.shot("pickup-qr")
        logout(page)
    browser.close()
