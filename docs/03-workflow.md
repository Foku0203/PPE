# Workflow Process: PPE Requisition & Issuance

## 1. ภาพรวมกระบวนการ

```mermaid
flowchart TD
    A[Worker Login: Employee ID / QR / Face Scan] --> B[เลือก PPE 3 ภาษา + ระบุขนาด จำนวน เหตุผล]
    B --> C{ตรวจ Quota, Lifespan และคำขอค้าง}
    C -- ผ่าน --> D[สร้างคำขอ: รออนุมัติ]
    C -- ก่อนกำหนด/เกินโควต้า --> E[Special Approval: เหตุผลและหลักฐาน]
    E --> F[Supervisor อนุมัติ]
    F --> G[จป./EHS อนุมัติ]
    G --> D
    D --> H[Supervisor อนุมัติคำขอปกติ]
    H --> I{คลังตรวจสต็อก}
    I -- ไม่พอ --> J[ON_HOLD_STOCK + แจ้งเตือน Reorder]
    I -- พอ --> K[คลังหยิบ/จองของ ตรวจ Lot/Serial]
    K --> L[อนุมัติแล้ว / พร้อมรับของ]
    L --> M[Worker รับของและยืนยัน]
    M --> N[ตัดสต็อก Real-time + บันทึกประวัติ]
    N --> O[รับสำเร็จ + Push Notification]
```

## 2. กระบวนการปกติแบบเป็นขั้นตอน

| ขั้น | ผู้รับผิดชอบ | การทำงาน | ผลลัพธ์/สถานะ |
|---:|---|---|---|
| 1 | Worker | ล็อกอิน เลือกภาษา และเปิด Catalog | พร้อมสร้างคำขอ |
| 2 | Worker | เลือก PPE ขนาด/จำนวน/เหตุผล แล้วส่ง | PENDING_APPROVAL |
| 3 | ระบบ | ตรวจสิทธิ์ Quota Lifespan คำขอซ้ำ และสต็อกเบื้องต้น | ผ่าน/แจ้งข้อผิดพลาด |
| 4 | Supervisor | ตรวจความจำเป็นและอนุมัติ/ปฏิเสธ | PENDING_APPROVAL หรือ REJECTED |
| 5 | คลัง/จป. | ตรวจ Policy/เอกสารและอนุมัติการจ่าย | APPROVED |
| 6 | Store Keeper | หยิบของตาม FIFO/FEFO ตรวจ Lot/Serial | READY_FOR_PICKUP |
| 7 | Worker/ผู้รับมอบอำนาจ | รับของ ตรวจรายการ และยืนยัน | COMPLETED |
| 8 | ระบบ | บันทึก Issue Transaction ตัดสต็อก และแจ้งเตือน | Audit ครบถ้วน |

## 3. กรณีเบิกก่อนกำหนดหรือเกินโควต้า

```mermaid
flowchart LR
    A[ระบบพบก่อน Lifespan/เกิน Quota] --> B[บังคับเหตุผลและหลักฐาน]
    B --> C{Supervisor อนุมัติ?}
    C -- ไม่อนุมัติ --> D[REJECTED + แจ้ง Worker]
    C -- อนุมัติ --> E{จป./EHS อนุมัติ?}
    E -- ไม่อนุมัติ --> D
    E -- อนุมัติ --> F[ส่งคลังตรวจสต็อก]
    F --> G[ดำเนินการตาม Workflow ปกติ]
```

## 4. กรณีสต็อกไม่เพียงพอ
- ระบบไม่อนุญาตให้ยอดติดลบ
- คำขอเปลี่ยนเป็น `ON_HOLD_STOCK` พร้อมเหตุผลและวันที่คาดว่าจะมีของ
- แจ้ง Store Keeper, EHS และ Worker
- สร้าง/อัปเดต Reorder Alert เมื่อยอดต่ำกว่า Reorder Point
- เมื่อเติมสต็อกแล้ว คลังตรวจสอบคำขอค้างตามลำดับความเร่งด่วนและ Policy ก่อนเปลี่ยนเป็น `APPROVED`

## 5. จุดควบคุมสำหรับ Harness
1. คลังสแกน Serial Number และ Lot Number ขณะหยิบ/จ่าย
2. ตรวจวันตรวจสภาพและวันหมดอายุ ต้องอยู่ในสถานะใช้งานได้
3. ห้ามจ่าย Serial เดิมให้ผู้รับซ้ำโดยไม่มีการคืน/ปลดสถานะ
4. บันทึกผู้รับ วันที่จ่าย และรอบตรวจครั้งถัดไป
5. หาก Serial ไม่ตรงคำขอ ให้หยุดรายการและบันทึก Exception

## 6. Notification Events
| Event | ผู้รับ | ช่องทาง |
|---|---|---|
| สร้างคำขอ | Supervisor, คลัง/จป. | Push + In-app |
| ต้องอนุมัติพิเศษ | Supervisor, จป./EHS | Push + In-app |
| อนุมัติ/ปฏิเสธ | Worker | Push + In-app |
| พร้อมรับของ | Worker | Push + In-app |
| Stock ต่ำ | คลัง, EHS, ผู้บริหารตามสิทธิ์ | Push + Dashboard |
| รับสำเร็จ | Worker, Supervisor, คลัง | In-app + Audit |
