# Implementation Status
## PPE Management Flutter + Django

สถานะ ณ วันที่ 2026-09-26

## สรุป

ระบบทำงานครบ workflow ตั้งแต่สมัคร/เข้าสู่ระบบ → เลือก PPE → ยื่นคำขอ → อนุมัติ (ปกติ/พิเศษ) → คลังจอง/จัดของ → สแกน QR รับของ → ตัดสต็อก → รับคืน
ครบทั้ง 5 role (Worker, Supervisor, Store keeper, EHS, Admin) ใช้ข้อมูลจาก backend จริงทุกหน้า รองรับ 4 ภาษา (TH/EN/MY/ZH)

การตรวจสอบที่ผ่านแล้ว:

| ชุดทดสอบ | ผล |
|---|---|
| Django `manage.py test ppe` (24 tests: workflow, สิทธิ์, quota, lifespan, anti-duplicate, ON_HOLD, QR replay, return, purchase request) | ผ่าน |
| `flutter analyze` | ไม่มี issue |
| `flutter test` (26 tests: models, error mapping, offline queue, route guard, ARB 4 ภาษา, widget login/ภาษา) | ผ่าน |
| E2E: Dart repositories จริง ↔ Django server จริง ครบทุก role (`test/e2e`) | ผ่าน |
| `flutter build web --release` | ผ่าน |

## ความสามารถตาม Module (README §5)

| Module | ทำแล้ว |
|---|---|
| Auth | Login ด้วย Employee ID, สมัครสมาชิก, JWT + refresh rotation + blacklist, session restore (ออฟไลน์ใช้ข้อมูล cache), logout + revoke device, biometric lock + ล็อกซ้ำเมื่อกลับเข้าแอปหลัง 1 นาที, role-based route guard |
| Catalog | 13 รายการพร้อมรูปจริง, ค้นหา/กรองหมวด/มีของ, ชื่อ 4 ภาษา, ตรวจสิทธิ์เบิก (quota/lifespan/คำขอค้าง), cache ออฟไลน์, EHS/Admin แก้ quota/lifespan/reorder/ขนาด/เปิด-ปิด พร้อมเหตุผล (audit) |
| Requisition | ตะกร้าหลายรายการ (บันทึก draft), ขนาด/จำนวน/เหตุผล, ตรวจสิทธิ์รายบรรทัด, เหตุผลอนุมัติพิเศษ, Idempotency-Key, คิวออฟไลน์ (pending/syncing/failed + retry), ติดตามสถานะ/ความคืบหน้า, ความคิดเห็น, ยกเลิก (คืนสต็อกที่จอง) |
| Approval | Inbox เฉพาะคำขอที่ผู้ใช้ต้องอนุมัติ (Supervisor เห็นเฉพาะทีม), อนุมัติ/ไม่อนุมัติ (บังคับเหตุผล)/ขอข้อมูลเพิ่ม, อนุมัติพิเศษ 2 ขั้น (Supervisor + EHS), SLA/overdue |
| Inventory | ภาพรวม available/reserved/issued 30 วัน, reorder alert, ล็อต/Serial/วันหมดอายุ (ไม่จองของหมดอายุ, FEFO), รับของเข้า (serial ต่อชิ้นสำหรับ harness/lanyard), ปรับยอด/ตัดชำรุด, ประวัติการเคลื่อนไหว, คำขอสั่งซื้อ PENDING→APPROVED→ORDERED→RECEIVED |
| Store / QR | คิวงาน (รอจัด/รอสต็อก/พร้อมรับ), จองและจัดของ, Worker แสดง QR ครั้งเดียว (หมดอายุ 5 นาที), คลังสแกนด้วยกล้อง (หรือพิมพ์) → ตรวจ → จ่ายของผูกกับ QR (กันการใช้ซ้ำ), ตรวจ Serial ตรงกับที่จอง, รับคืน (ดี/ชำรุด) |
| Notifications | Feed in-app, badge, อ่าน/ยังไม่อ่าน/อ่านทั้งหมด, แตะเพื่อเปิดคำขอ, polling 30 วินาที, FCM push (เมื่อตั้งค่า Firebase) |
| Dashboard | KPI ตาม role, แจ้งเตือนครบอายุเปลี่ยน, low stock, compliance ของทีม/โรงงาน, คำขอล่าสุด, หน้า Analytics |
| Profile / Admin | แก้โปรไฟล์, เปลี่ยนรหัสผ่าน, ภาษา ไทย/อังกฤษ/พม่า/จีน (บันทึกทั้งในเครื่องและ server), PPE ของฉัน, คิวออฟไลน์, จัดการผู้ใช้/สิทธิ์/หัวหน้างาน, Audit log |

## สิ่งที่ต้องตั้งค่าเองก่อนใช้งานจริง (ทำแทนไม่ได้จากเครื่องนี้)

1. **Firebase push** – ต้องมี Firebase project ของหน่วยงาน (`google-services.json`, `GoogleService-Info.plist`, service account) ดู `ppe_mobile_app/README.md`
2. **Build Android/iOS** – เครื่องที่พัฒนานี้ไม่มี Android SDK/Xcode จึงยังไม่ได้ build APK/IPA และทดสอบบนมือถือจริง (โค้ด/permission/manifest ตั้งค่าไว้แล้ว)
3. **Application ID / signing** – เปลี่ยน `com.example.ppe_mobile_app` และตั้ง keystore/Apple team
4. **Production** – `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=False`, PostgreSQL, HTTPS, เปลี่ยนรหัสผ่านบัญชีทดลอง
5. **คำแปลภาษาพม่าและจีน** – ควรให้เจ้าของภาษาตรวจทาน

## ข้อจำกัด/งานต่อยอดที่แนะนำ

- อัปโหลดรูปหลักฐาน (ชำรุด/สูญหาย) ประกอบคำขอพิเศษ
- Login ด้วย OTP / QR challenge (ปัจจุบันใช้ Employee ID + รหัสผ่าน)
- Certificate pinning, Sentry/crash reporting
- รายงานส่งออก (Excel/PDF) และกราฟย้อนหลังหลายเดือน
