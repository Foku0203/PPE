# Django Backend

## Setup (Windows PowerShell)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe manage.py migrate
.\.venv\Scripts\python.exe manage.py seed_ppe
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
.\.venv\Scripts\python.exe manage.py test ppe
```

`seed_ppe` สร้าง PPE 13 รายการ (3 ภาษา, ตรงกับรูปใน `ppe_mobile_app/assets/images/ppe/`), สต็อก/ล็อต/Serial, ผู้ใช้ทุก role และคำขอตัวอย่างทุกสถานะ
(`--no-requests` เพื่อไม่สร้างคำขอตัวอย่าง) — รหัสผ่านทุกบัญชี `ChangeMe123!`: `ADMIN001`, `EHS001`, `STORE001`, `SUP001`, `EMP001`, `EMP002`
**เปลี่ยนรหัสผ่านทันทีเมื่อใช้จริง**

ฐานข้อมูล: SQLite (`DATABASE_URL=sqlite:///db.sqlite3`) สำหรับ dev หรือ PostgreSQL (`DATABASE_URL=postgres://user:pass@host:5432/ppe`) สำหรับ production

## มาตรฐาน API

- Auth: `Authorization: Bearer <access>` (JWT อายุสั้น, refresh token หมุนทุกครั้งและ blacklist ตัวเก่า)
- Mutation ส่ง `Idempotency-Key`; การสร้างคำขอใช้เป็น `client_request_id` ถ้าไม่ส่งใน body → ส่งซ้ำไม่เกิดคำขอซ้ำ
- Error ทุกกรณี: `{"success": false, "error": {"code", "message", "details"}}`
  รหัสธุรกิจ เช่น `ACTIVE_REQUEST_EXISTS`, `SPECIAL_REASON_REQUIRED`, `SIZE_REQUIRED`, `NOT_ALLOWED_TO_APPROVE`, `INVALID_STATUS`,
  `SERIAL_MISMATCH`, `SERIAL_REQUIRED`, `QR_INVALID`, `QR_MISMATCH`, `NEGATIVE_STOCK`, `INVALID_CREDENTIALS`
- รายการแบบแบ่งหน้า: `{"count", "next", "previous", "results"}` (`?page_size=` สูงสุด 200)
- คำขอแต่ละรายการมี `actions` (`can_approve`, `can_prepare`, `can_issue`, …) คำนวณจากสิทธิ์ผู้ใช้ปัจจุบัน

## Endpoints (`/api/v1/`)

| Method | Path | ใคร | หมายเหตุ |
|---|---|---|---|
| POST | `auth/token/` | ทุกคน | `{employee_id, password}` → `{access, refresh, user}` |
| POST | `auth/token/refresh/` | ทุกคน | rotate refresh |
| POST | `auth/register/` | ทุกคน | สร้างบัญชี Worker (`supervisor_employee_id` ไม่บังคับ) |
| POST | `auth/logout/` | login | blacklist refresh + ปิด device token |
| GET/PATCH | `me/` | login | โปรไฟล์ (ชื่อ, เบอร์, แผนก, locale) |
| POST | `me/password/` | login | เปลี่ยนรหัสผ่าน |
| GET | `me/issued-items/` | login | PPE ที่ถืออยู่ + วันครบกำหนดเปลี่ยน |
| GET | `users/` · PATCH `users/{id}/` | Supervisor+ / Admin | ค้นหาผู้ใช้ · แก้ role/supervisor/active |
| POST | `devices/token/` | login | ลงทะเบียน FCM/APNs token |
| GET | `notifications/` `notifications/unread-count/` | login | |
| POST | `notifications/{id}/read/` (`{"unread": true}` = ยังไม่อ่าน) · `notifications/read-all/` | login | |
| GET/POST | `catalog/ppe/?locale=TH&search=&category=` | อ่าน: login · สร้าง: EHS/Admin | |
| GET/PATCH | `catalog/ppe/{id}/` | อ่าน: login · แก้: EHS/Admin (ต้องมี `change_reason`) | |
| GET | `catalog/ppe/{id}/eligibility/?quantity=` | login | quota / lifespan / คำขอซ้ำ |
| GET/POST | `requisitions/?scope=mine|team|inbox|store&status=&search=` | login | |
| GET | `requisitions/{id}/` | ผู้เกี่ยวข้อง | รวม items, approvals, comments, stock_events |
| POST | `requisitions/{id}/cancel/` | ผู้ขอ / คลัง | คืนสต็อกที่จองไว้ |
| POST | `requisitions/{id}/approvals/` | Supervisor(ทีมตัวเอง)/EHS/Admin | `decision`: `APPROVED`, `REJECTED` (ต้องมีเหตุผล), `REQUEST_INFO` |
| GET/POST | `requisitions/{id}/comments/` | ผู้เกี่ยวข้อง | |
| POST | `requisitions/{id}/pickup-qr/` | ผู้ขอ (READY) | QR ใช้ครั้งเดียว อายุ `QR_TOKEN_MINUTES` |
| POST | `requisitions/{id}/prepare/` | คลัง | จอง FEFO; ของไม่พอ → `ON_HOLD_STOCK` |
| POST | `requisitions/{id}/issue/` | คลัง | `{serial_numbers?, qr_token?}` |
| POST | `requisition-items/{id}/return/` | คลัง | `{condition: GOOD|DAMAGED, note}` |
| GET/POST | `inventory/lots/` | คลัง | รายการล็อต · รับของเข้า |
| POST | `inventory/lots/{id}/adjust/` | คลัง | `{delta, reason, event_type: ADJUSTMENT|DAMAGE}` |
| GET | `inventory/summary/` `inventory/events/` | คลัง | |
| POST | `inventory/scan/resolve/` | คลัง | ตรวจ QR (ไม่ใช้ token จนกว่าจะ issue) |
| GET/POST | `purchase-requests/` · POST `purchase-requests/{id}/status/` | คลัง/EHS/Admin | PENDING→APPROVED→ORDERED→RECEIVED |
| GET | `dashboard/summary/` | login | KPI ตาม role + compliance + low stock + recent |
| GET | `audit-logs/` | EHS/Admin | |

## Push notification

`Notification` คือ in-app feed/outbox ทุกครั้ง; ส่ง push จริงผ่าน `ppe/push.py` เมื่อติดตั้ง `firebase-admin` และตั้ง `FIREBASE_CREDENTIALS`
