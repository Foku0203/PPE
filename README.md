# PPE SMART – ระบบเบิกจ่ายอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล

ระบบเบิก–อนุมัติ–จ่าย PPE สำหรับโรงงาน ใช้ได้ทั้งบนมือถือ (Android / iOS) และคอมพิวเตอร์ผ่านเว็บ
พนักงานยื่นคำขอเบิก หัวหน้าอนุมัติ คลังจัดของและจ่ายโดยสแกน QR ส่วน EHS/Admin ดูแลแคตตาล็อก สต็อก และสิทธิ์

| ส่วน | เทคโนโลยี | โฟลเดอร์ |
|---|---|---|
| แอป (มือถือ + เว็บ) | Flutter 3, Riverpod, go_router, Dio, Hive | [`ppe_mobile_app/`](ppe_mobile_app/) |
| Backend / API | Django 5 + Django REST Framework + JWT | [`backend/`](backend/) |
| ฐานข้อมูล | SQLite (dev) / PostgreSQL (production) | `backend/db.sqlite3` |
| เอกสาร | SRS, workflow, สถาปัตยกรรม, สถานะงาน | [`docs/`](docs/) |

## ความสามารถหลัก

- **5 บทบาท**: พนักงาน, หัวหน้างาน, เจ้าหน้าที่คลัง, EHS, ผู้ดูแลระบบ – เมนูและสิทธิ์ต่างกันตามบทบาท
- **เบิก PPE**: เลือกจากแคตตาล็อก 13 รายการ (มีรูป, ชื่อ 4 ภาษา) ใส่ตะกร้าหลายรายการ ระบุขนาด/จำนวน/เหตุผล
- **ตรวจสิทธิ์อัตโนมัติ**: โควต้าต่อครั้ง, อายุการใช้งาน, กันยื่นคำขอซ้ำ – ถ้าเกินสิทธิ์ต้องขออนุมัติพิเศษ (หัวหน้า + EHS)
- **อนุมัติ**: อนุมัติ / ไม่อนุมัติ (ต้องมีเหตุผล) / ขอข้อมูลเพิ่ม พร้อมแจ้งเตือนเมื่อเกิน SLA
- **คลัง**: จองของแบบ FEFO, ล็อต/Serial/วันหมดอายุ, รับของเข้า, ปรับยอด, คำขอสั่งซื้อ, แจ้งเตือนสต็อกต่ำ
- **จ่ายของด้วย QR**: พนักงานแสดง QR ใช้ครั้งเดียว (หมดอายุ 5 นาที) คลังสแกนแล้วจ่าย – กันการใช้ QR ซ้ำ
- **ออฟไลน์**: ส่งคำขอตอนเน็ตหลุดได้ ระบบเก็บเข้าคิวแล้วส่งให้เองเมื่อเน็ตกลับ (ไม่เกิดคำขอซ้ำ)
- **อื่น ๆ**: แจ้งเตือนในแอป, Dashboard/KPI ตามบทบาท, Audit log, 4 ภาษา (ไทย/อังกฤษ/พม่า/จีน), โหมดสว่าง/มืด, ล็อกด้วยลายนิ้วมือ

รายละเอียดการทำงานทุกหน้าจออยู่ในคู่มือ `docs/PPE-SMART-คู่มือระบบ.docx`

## เริ่มใช้งาน (Windows)

ต้องมี Python 3.13 และ Flutter (stable)

```powershell
# 1) Backend – ใช้ venv เดียวที่ root ของโปรเจกต์
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
cd backend
Copy-Item .env.example .env
..\.venv\Scripts\python.exe manage.py migrate
..\.venv\Scripts\python.exe manage.py seed_ppe        # ข้อมูลตัวอย่าง + บัญชีทดลอง
..\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000

# 2) แอป (อีกหน้าต่าง)
cd ppe_mobile_app
flutter pub get
flutter run -d chrome        # หรือ -d <android device>
```

บัญชีทดลอง (รหัสผ่าน `ChangeMe123!`): `EMP001` พนักงาน · `SUP001` หัวหน้า · `STORE001` คลัง · `EHS001` EHS · `ADMIN001` ผู้ดูแล
**เปลี่ยนรหัสผ่านก่อนให้คนอื่นใช้จริง**

## ให้คนภายนอกเข้าใช้ผ่านลิงก์ / QR code

ใช้ได้ทั้ง iPhone, Android และคอม ผู้ใช้ไม่ต้องติดตั้งอะไร แค่สแกน QR หรือกดลิงก์

1. Build แอปเวอร์ชันเว็บ (ทำใหม่ทุกครั้งที่แก้โค้ดแอป):
   ```powershell
   cd ppe_mobile_app; flutter build web --release
   ```
2. ดับเบิลคลิก **`start_public.bat`** – สคริปต์จะเปิด ngrok + Django แล้วสร้าง `qr_code.png` ให้
3. ส่งลิงก์/QR ให้ผู้ใช้ และเปิดหน้าต่างสคริปต์ค้างไว้ (กด Enter เพื่อปิดระบบ)

- ต้องติดตั้ง [ngrok](https://ngrok.com) และตั้ง authtoken แล้ว
- ครั้งแรกสคริปต์จะถามชื่อโดเมนถาวรฟรีจาก [ngrok dashboard](https://dashboard.ngrok.com/domains) แล้วจำไว้ใน `public_domain.txt` ลิงก์/QR จะไม่เปลี่ยนอีก (ลบไฟล์นี้เพื่อเปลี่ยนโดเมน, กด Enter ข้ามเพื่อใช้ลิงก์สุ่ม)
- ระหว่างที่สคริปต์เปิดอยู่ คอมจะไม่เข้าโหมด Sleep (ปิดสคริปต์แล้วกลับเป็นปกติ) – ถ้าเป็นโน้ตบุ๊ก อย่าพับจอ
- ครั้งแรกผู้ใช้จะเห็นหน้าเตือนของ ngrok ให้กด **Visit Site**
- ถ้าพอร์ต 8000 ถูกใช้อยู่ รัน `start_public.ps1 -Port 8765`

Django เสิร์ฟทั้งหน้าแอป (`/`) และ API (`/api/v1/`) จากที่อยู่เดียวกัน แอปเวอร์ชันเว็บจึงหา API เองได้โดยไม่ต้องตั้งค่า

## ทดสอบ

```powershell
cd backend; ..\.venv\Scripts\python.exe manage.py test ppe     # 24 tests
cd ppe_mobile_app; flutter analyze; flutter test                # 26 tests
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) รัน backend tests, flutter analyze/test และ E2E (แอป ↔ Django จริง)

## คำแปล 4 ภาษา และการตรวจด้วย LLM

ข้อความในแอปอยู่ใน `ppe_mobile_app/lib/l10n/app_<th|en|my|zh>.arb` (ภาษาอังกฤษเป็นต้นแบบ) ขั้นตอนเมื่อแก้คำแปลมีดังนี้

1. **แก้ไฟล์ `.arb`**
2. **ตรวจคำแปลด้วย LLM (ไม่บังคับ)** สคริปต์ [`ppe_mobile_app/tool/review_translations.py`](ppe_mobile_app/tool/review_translations.py) ส่งคำแปลภาษาไทย พม่า และจีน พร้อมต้นฉบับภาษาอังกฤษ ให้ Claude (`claude-opus-5-5`) ตรวจ 5 เรื่อง ได้แก่ ความหมาย ไวยากรณ์ คำศัพท์ด้านความปลอดภัย/PPE ระดับภาษา และ placeholder ผลลัพธ์เป็นรายงาน `docs/translation-review.md`
   - สคริปต์**ไม่แก้ไฟล์ `.arb` เอง** ให้คนอ่านรายงานแล้วเลือกแก้ด้วยมือ
   - ภาษาพม่าควรให้เจ้าของภาษาตรวจซ้ำ เพราะ LLM แม่นภาษาพม่าน้อยกว่าภาษาอื่น
   - มีค่าใช้จ่าย API ทุกครั้งที่รัน และข้อความในแอปจะถูกส่งไปยัง Anthropic
3. **`flutter gen-l10n`** สร้างโค้ด Dart (`app_localizations*.dart`) จากไฟล์ `.arb`
4. **`flutter test`** ตรวจว่าทุกภาษามี key และ placeholder ครบตรงกัน

```powershell
.\.venv\Scripts\python.exe -m pip install anthropic pydantic       # ครั้งแรก
$env:ANTHROPIC_API_KEY = "sk-ant-..."
.\.venv\Scripts\python.exe ppe_mobile_app\tool\review_translations.py --dry-run     # ดูขนาดข้อมูล ไม่เรียก API
.\.venv\Scripts\python.exe ppe_mobile_app\tool\review_translations.py               # ตรวจ th, my, zh
.\.venv\Scripts\python.exe ppe_mobile_app\tool\review_translations.py --langs th    # ตรวจบางภาษา
```

LLM ใช้เฉพาะตอนพัฒนาเพื่อตรวจคำแปล ตัวแอปและ backend ไม่ได้เรียก LLM ตอนใช้งานจริง

## โครงสร้างโปรเจกต์

```text
PPE/
├── backend/              Django API (app `ppe` = models, views, business rules, tests)
├── ppe_mobile_app/       Flutter app
│   ├── lib/app/          theme, routes, config
│   ├── lib/core/         network (Dio + JWT refresh), storage, errors
│   ├── lib/features/     หน้าจอแยกตามโมดูล (auth, home, catalog, requisitions, approval, inventory, …)
│   ├── lib/shared/       models, providers, widgets กลาง
│   ├── lib/l10n/         คำแปล 4 ภาษา (.arb)
│   └── tool/             สคริปต์ตรวจคำแปลด้วย LLM (review_translations.py)
├── docs/                 SRS, proposal, workflow, catalog, traceability, architecture, status
├── image/                ไฟล์ต้นฉบับรูปแบนเนอร์/ไอคอน
├── start_public.ps1/.bat เปิดระบบให้คนภายนอกเข้าผ่านลิงก์/QR
└── .github/workflows/    CI
```

เอกสารเพิ่มเติม: [API และ backend](backend/backend_README.md) · [แอป Flutter](ppe_mobile_app/README.md) · [สถานะงาน](docs/07-implementation-status.md)


# 1) build แอปเวอร์ชันเว็บใหม่ ทำเฉพาะตอนที่แก้โค้ด Flutter (ถ้าไม่ build ลิงก์จะยังเป็นแอปเวอร์ชันเก่า)
cd D:\PPE\ppe_mobile_app
flutter build web --release

# 2) เปิดเซิร์ฟเวอร์ + ลิงก์สาธารณะ + QR code
cd D:\PPE
.\start_public.bat
