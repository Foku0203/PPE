"""Captures real screenshots of the PPE SMART app for the showcase page.

Needs: backend on :8000 (python manage.py runserver) and the web build served on :8080
(cd ppe_mobile_app/build/web; python -m http.server 8080). Uses the installed Google Chrome.
"""
import os
import sys
import time

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:8080/#"
OUT = r"D:\PPE\showcase\shots"
PROFILE = r"D:\PPE\showcase\.chrome-profile"
os.makedirs(OUT, exist_ok=True)
only = set(sys.argv[1:])


def settle(page, seconds=3.5):
    time.sleep(seconds)


def semantics(page):
    """Flutter web renders to canvas; enabling semantics exposes buttons/text to locators."""
    if page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) { p.click(); return true; } return false; }"):
        time.sleep(0.8)


def shot(page, name):
    if only and name not in only:
        return
    page.screenshot(path=os.path.join(OUT, f"{name}.png"))
    print("saved", name)


def logout(page):
    page.evaluate("() => { localStorage.clear(); sessionStorage.clear(); indexedDB.databases && indexedDB.databases().then(d => d.forEach(x => indexedDB.deleteDatabase(x.name))); }")
    time.sleep(1)


def login(page, employee_id):
    page.goto(f"{BASE}/login")
    settle(page, 5)
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
    settle(page, 5)


def go(page, path, wait=4):
    page.goto(f"{BASE}{path}")
    settle(page, wait)
    semantics(page)


with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        PROFILE, channel="chrome", headless=True, locale="th-TH",
        viewport={"width": 390, "height": 844}, device_scale_factor=2)
    page = ctx.pages[0] if ctx.pages else ctx.new_page()

    # Login screen in the four languages.
    page.goto(f"{BASE}/login")
    settle(page, 6)
    logout(page)
    page.reload()
    settle(page, 6)
    shot(page, "login-th")
    semantics(page)
    for label, name in [("English", "login-en"), ("မြန်မာ", "login-my"), ("中文", "login-zh"), ("ไทย", None)]:
        page.mouse.click(330, 28)  # translate icon in the login app bar
        time.sleep(1.2)
        page.get_by_role("menuitem", name=label).first.click()
        settle(page, 2)
        if name:
            shot(page, name)

    # Worker
    login(page, "EMP001")
    shot(page, "worker-home")
    go(page, "/catalog")
    shot(page, "worker-catalog")
    go(page, "/catalog/item/1")
    shot(page, "worker-ppe-detail")
    page.get_by_role("button", name="เบิกรายการนี้").first.click()
    settle(page, 4)
    shot(page, "worker-new-request")
    go(page, "/requests")
    shot(page, "worker-requests")
    go(page, "/requests/5")
    shot(page, "worker-request-special")
    go(page, "/profile/my-ppe")
    shot(page, "worker-my-ppe")
    logout(page)

    # Worker 2: pickup QR
    login(page, "EMP002")
    go(page, "/requests/2")
    shot(page, "worker-request-ready")
    page.get_by_role("button", name="แสดง QR รับของ").first.click()
    settle(page, 4)
    shot(page, "worker-pickup-qr")
    logout(page)

    # Supervisor
    login(page, "SUP001")
    shot(page, "supervisor-home")
    go(page, "/approvals")
    shot(page, "supervisor-approvals")
    go(page, "/requests/4")
    shot(page, "supervisor-approve")
    logout(page)

    # Store keeper
    login(page, "STORE001")
    shot(page, "store-home")
    go(page, "/store")
    shot(page, "store-queue")
    go(page, "/inventory")
    shot(page, "store-inventory")
    go(page, "/inventory/item/12")
    shot(page, "store-lots")
    go(page, "/inventory/receive")
    shot(page, "store-receive")
    logout(page)

    # EHS & Admin
    login(page, "EHS001")
    shot(page, "ehs-home")
    go(page, "/catalog/manage")
    shot(page, "ehs-manage-catalog")
    logout(page)
    login(page, "ADMIN001")
    go(page, "/analytics")
    shot(page, "admin-analytics")
    go(page, "/admin/users")
    shot(page, "admin-users")
    go(page, "/admin/audit")
    shot(page, "admin-audit")
    go(page, "/notifications")
    shot(page, "admin-notifications")
    logout(page)
    ctx.close()
