# Requirements Traceability Matrix (RTM)

| Business Objective / Need | Requirement | Process / Module | Acceptance Evidence | Owner |
|---|---|---|---|---|
| เบิก PPE สะดวก รวดเร็ว ถูกต้อง | FR-01, FR-02 | Authentication, Catalog, Requisition | UAT: Worker สร้างคำขอครบข้อมูล | Product/EHS |
| รองรับแรงงานหลายภาษา | Language/UX 3 ภาษา | Catalog, Mobile/Web | Screenshot/UX Test ไทย อังกฤษ พม่า + Icons | BA/UX |
| ลดการเบิกซ้ำซ้อน | FR-03 | Anti-Duplicate, Quota, Lifespan | Test: คำขอซ้ำ/ก่อนกำหนดถูกเตือนหรือบล็อก | EHS/QA |
| ควบคุมกรณีพิเศษ | FR-03, FR-05 | Special Approval | Test: ต้องผ่าน Supervisor และ จป./EHS | EHS/QA |
| ลดปัญหาสต็อกขาด | FR-04, FR-07 | Inventory, Reorder Alert | Test: ยอดต่ำกว่า ROP สร้าง Alert | Store/QA |
| ยอดคลังเป็นปัจจุบัน | FR-04 | Issue Transaction | Test: จ่ายสำเร็จตัด Real-time และห้ามติดลบ | Store/IT |
| ตรวจสอบ Harness ย้อนกลับ | FR-04 | Serial/Lot Control | Test: Serial/Lot -> ผู้รับ -> วันจ่าย -> ตรวจสภาพ | Store/EHS |
| ติดตามคำขอได้ | FR-05, FR-06 | Approval/Status | Test: ครบ 4 สถานะและเปลี่ยนตามสิทธิ์ | PM/QA |
| แจ้งเตือนทันเวลา | FR-05 | Push Notification | Test: Event สำคัญได้รับ Push/In-app | IT/QA |
| รักษาความปลอดภัยข้อมูล | NFR-03, NFR-04 | Security/Privacy | Security Test, Access Test, Privacy Review | IT/Legal |
| ตรวจสอบย้อนหลังได้ | NFR-05 | Audit Log/Reports | Audit evidence ก่อน-หลังและผู้ทำรายการ | IT/Internal Audit |
| รองรับการใช้งานจริง | NFR-01, NFR-02, NFR-06, NFR-08 | Platform/Operations | Performance, Availability, Backup Restore | IT/DevOps |

## Definition of Done สำหรับ Requirement
- มีรายละเอียดและกติกาธุรกิจที่ได้รับอนุมัติ
- มี UX/ข้อความ 3 ภาษาที่ผ่านการทบทวน
- มี Test Case อย่างน้อยหนึ่งกรณีสำเร็จและหนึ่งกรณีผิดเงื่อนไข
- มี Audit/Security/Privacy impact ตามความเหมาะสม
- UAT Owner ลงนามรับรองและ Requirement สถานะ `Verified`
