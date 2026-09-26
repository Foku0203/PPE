# PPE Management – Flutter app

แอปมือถือ (Android / iOS / Web) สำหรับเบิก–อนุมัติ–จ่าย PPE เชื่อมกับ Django backend ใน `../backend`

## เริ่มใช้งานเร็ว (ครั้งแรก)

```powershell
# 1) Backend
cd backend
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py seed_ppe          # สินค้า 13 รายการ + ผู้ใช้ทุก role + คำขอตัวอย่าง
python manage.py runserver 0.0.0.0:8000

# 2) App (อีกหน้าต่าง)
cd ppe_mobile_app
flutter pub get
flutter run -d chrome              # หรือ -d <android/ios device>
```

บัญชีทดลอง (รหัสผ่าน `ChangeMe123!` แตะชิปบนหน้า Login เพื่อกรอกอัตโนมัติ):

| Employee ID | Role | สิ่งที่ทำได้ |
|---|---|---|
| EMP001, EMP002 | Worker | ดู Catalog, สร้างคำขอ, แสดง QR รับของ, PPE ของฉัน |
| SUP001 | Supervisor | อนุมัติ/ไม่อนุมัติ/ขอข้อมูลเพิ่ม ของทีมตัวเอง, สรุปภาพรวมทีม |
| STORE001 | Store keeper | จอง/จัดของ, สแกน QR จ่ายของ, รับคืน, รับของเข้า, ปรับยอด, ขอสั่งซื้อ |
| EHS001 | EHS (จป.) | อนุมัติพิเศษ, แก้นโยบาย quota/lifespan/reorder, Audit log, สต็อก |
| ADMIN001 | Admin | ทุกอย่าง + จัดการผู้ใช้/สิทธิ์ |

### URL ของ API
ค่าเริ่มต้น: Web/iOS simulator → `http://127.0.0.1:8000/api/v1`, Android emulator → `http://10.0.2.2:8000/api/v1`

- เครื่องจริง: กดไอคอน **เซิร์ฟเวอร์** มุมขวาบนของหน้า Login แล้วใส่ `http://<IP เครื่อง backend>:8000/api/v1` (จำค่าไว้ในเครื่อง)
  และตั้ง `DJANGO_ALLOWED_HOSTS` ใน backend ให้มี IP นั้น
- หรือ build-time: `flutter run --dart-define=API_BASE_URL=https://ppe.example.com/api/v1 --dart-define=APP_ENV=production`
  (`APP_ENV=production` จะซ่อนปุ่มบัญชีทดลอง)

## โครงสร้าง

```
lib/
├── app/            app.dart, config/, routes/ (go_router + role guard), theme/
├── core/           constants/api_endpoints, errors/ (ApiException, NoInternet, Timeout, Validation),
│                   network/ (Dio + token refresh + Idempotency-Key), storage/ (secure storage + Hive), utils/
├── l10n/           app_en.arb, app_th.arb, app_my.arb, app_zh.arb  → generated AppLocalizations
├── shared/         models/, providers/ (settings, api client), services/push_service, widgets/
└── features/
    ├── auth/           login, register, lock (biometric), splash, AuthController (session restore)
    ├── home/           หน้าหลักตาม role (KPI, แจ้งเตือนครบอายุ, low stock, compliance)
    ├── catalog/        แคตตาล็อก + รายละเอียด + ตรวจสิทธิ์ + แก้นโยบาย (EHS/Admin)
    ├── requisitions/   รายการ/สร้าง/รายละเอียดคำขอ, cart draft, offline queue
    ├── approval/       Inbox ผู้อนุมัติ (SLA/overdue)
    ├── store/          คิวงานคลัง (รอจัด / รอสต็อก / พร้อมรับ)
    ├── inventory/      สต็อก, ล็อต/Serial, รับของเข้า, สแกน QR, คำขอสั่งซื้อ
    ├── notifications/  รายการแจ้งเตือน + badge (poll + push)
    ├── dashboard/      Analytics
    ├── profile/        โปรไฟล์, ภาษา, biometric, เปลี่ยนรหัส, PPE ของฉัน, คิวออฟไลน์
    └── admin/          ผู้ใช้/สิทธิ์, Audit log
```

State management: Riverpod 3 · Routing: go_router · HTTP: Dio · Storage: flutter_secure_storage (token) + Hive (cache/draft/queue)

## การแปลภาษา (TH / EN / MY / ZH)

แก้ข้อความที่ `lib/l10n/app_*.arb` (ทั้ง 4 ไฟล์ต้องมี key เดียวกัน – มี test ตรวจ) แล้วรัน `flutter gen-l10n`
ชื่อ PPE มาจาก backend (`PpeTranslation`) ส่วนข้อความแจ้งเตือนแปลฝั่งแอปจาก `notification_type`
> คำแปลภาษาพม่าและจีนควรให้เจ้าของภาษาตรวจทานก่อนใช้งานจริง

## ทดสอบ

```powershell
flutter analyze
flutter test --exclude-tags e2e        # unit + widget

# Contract/E2E กับ backend จริง (ฐานข้อมูลแยก)
cd ../backend
$env:DATABASE_URL="sqlite:///e2e.sqlite3"; python manage.py migrate; python manage.py seed_ppe --no-requests
$env:DATABASE_URL="sqlite:///e2e.sqlite3"; python manage.py runserver 127.0.0.1:8765
cd ../ppe_mobile_app
flutter test test/e2e --dart-define=E2E_BASE_URL=http://127.0.0.1:8765/api/v1
```

CI (`.github/workflows/ci.yml`) รันทั้ง backend tests, flutter analyze/test และ E2E

## Push notification (ทางเลือก)

แอปทำงานได้ครบโดยไม่ต้องมี Firebase (badge/รายการแจ้งเตือนใช้การ poll ทุก 30 วินาที) หากต้องการ push จริง:
1. สร้าง Firebase project แล้ววาง `android/app/google-services.json` และ `ios/Runner/GoogleService-Info.plist`
   (หรือรัน `flutterfire configure`) และเพิ่ม plugin `com.google.gms.google-services` ใน Gradle
2. Backend: `pip install firebase-admin` และตั้ง `FIREBASE_CREDENTIALS=<path service-account.json>`

## Release

- Android: เปลี่ยน `applicationId` (`android/app/build.gradle.kts`) และตั้ง signing config ก่อน `flutter build apk --release`
- iOS: ตั้ง Bundle ID / Team ใน Xcode แล้ว `flutter build ios --release`
- Release build ต้องใช้ HTTPS (debug อนุญาต HTTP สำหรับ dev เท่านั้น)
