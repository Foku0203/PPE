# Django Backend

## Setup (Windows PowerShell)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe manage.py migrate
.\.venv\Scripts\python.exe manage.py seed_ppe
.\.venv\Scripts\python.exe manage.py runserver 8000
```

Demo user: `ADMIN001` / `ChangeMe123!` (เปลี่ยนรหัสผ่านทันทีเมื่อใช้จริง)

## API หลัก

- `POST /api/v1/auth/token/` body `{ "employee_id": "ADMIN001", "password": "..." }`
- `POST /api/v1/auth/token/refresh/`
- `GET /api/v1/me/`
- `POST /api/v1/devices/token/` ลงทะเบียน FCM/APNs/Web Push device token
- `GET /api/v1/notifications/`
- `POST /api/v1/notifications/{id}/read/`
- `GET /api/v1/catalog/ppe/?locale=TH`
- `POST /api/v1/requisitions/`
- `POST /api/v1/requisitions/{id}/approvals/`
- `POST /api/v1/requisitions/{id}/prepare/`
- `POST /api/v1/requisitions/{id}/issue/`
- `GET /api/v1/inventory/lots/`
- `POST /api/v1/inventory/scan/challenge/`
- `POST /api/v1/inventory/scan/resolve/`
- `GET /api/v1/dashboard/summary/`

`Notification` เป็น outbox/log สำหรับส่งต่อไปยัง FCM/APNs/Web Push worker โดยยังไม่ผูก provider ใดแบบ hard-coded ส่วน `FaceCredential` เก็บ provider reference/hash และ consent เท่านั้น ไม่เก็บภาพใบหน้าดิบ

ใช้ `Authorization: Bearer <access>` กับ endpoint ที่ต้อง login และส่ง `Idempotency-Key`/`client_request_id` จาก mobile เมื่อสร้างคำขอ


#เพิ่มคงคลัง ทำหน้าที่อนุมัติรายการอุปกรณ์เบิก
#แก้ UI HTML