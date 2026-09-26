# PPE Catalog และข้อมูลควบคุมคลัง

## 1. รายการ PPE มาตรฐาน 3 ภาษา

| รหัสตัวอย่าง | ภาษาไทย | English | မြန်မာ | ไอคอน/ภาพ | หน่วย |
|---|---|---|---|---|---|
| PPE-HLM | หมวกนิรภัย | Safety Helmet | ဘေးကင်း ဦးထုပ် | `helmet` | ชิ้น |
| PPE-BOT | รองเท้านิรภัย | Safety Boots | လုံခြုံရေးဖိနပ် | `boots` | คู่ |
| PPE-GOG | แว่นตานิรภัย | Safety Goggles | အကာအကွယ်မျက်မှန် | `goggles` | ชิ้น |
| PPE-VST | ชุดป้องกันและเสื้อสะท้อนแสง | Body Protection / Safety Vest | ရောင်ပြန်အင်္ကျ | `vest` | ชุด/ตัว |
| PPE-HAR | อุปกรณ์ป้องกันการตก / สายรัดนิรภัย | Fall Protection / Safety Harness | ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ် | `harness` | ชุด |
| PPE-GLV | ถุงมือนิรภัย | Safety Gloves | ဘေးကင်းလုံခြုံရေး လက်အိတ် | `gloves` | คู่ |
| PPE-EAR-P | อุปกรณ์ป้องกันเสียง | Earplug | နားဆို့ | `earplug` | คู่ |
| PPE-EAR-M | อุปกรณ์ป้องกันเสียง | Earmuff | နားဖုံးကိရိယာ | `earmuff` | ชิ้น |
| PPE-N95 | หน้ากาก N95 | N95 Mask | N95 အသက်ရှူကာမျက်နှာဖုံး | `mask` | ชิ้น |

## 2. ฟิลด์ข้อมูลที่ต้องกำหนดต่อรายการ

| ฟิลด์ | คำอธิบาย | ตัวอย่าง/ค่า |
|---|---|---|
| PPE Code | รหัสไม่ซ้ำ | PPE-HLM |
| Category | หมวด PPE | Head Protection |
| Size | ขนาด/ความพอดี | S, M, L, XL, Universal |
| Unit | หน่วยนับ | ชิ้น, คู่, ชุด |
| Quota | จำนวนสูงสุด/รอบ | [ระบุโดย EHS] |
| Lifespan | อายุใช้งาน/วัน | [ระบุโดย EHS/ผู้ผลิต] |
| Reorder Point | จุดสั่งซื้อใหม่ | [ระบุโดยคลัง] |
| Minimum/Maximum | ระดับคลังควบคุม | [ระบุ] |
| Lot/Expiry | รุ่นผลิต/หมดอายุ | บังคับตามชนิด |
| Serial Required | ต้องระบุ Serial หรือไม่ | บังคับสำหรับ Harness |
| Inspection Rule | เงื่อนไขตรวจสภาพ | บังคับสำหรับ Harness |
| Active/Inactive | เปิดใช้ใน Catalog | Active |

## 3. กติกาเฉพาะกลุ่ม
- Helmet, Boots, Goggles, Vest, Gloves และ Ear Protection ต้องรองรับขนาดเมื่อผู้ผลิตกำหนด
- N95 ต้องเก็บ Lot/Expiry และเตือนไม่ให้จ่ายของหมดอายุ
- Harness ต้องใช้ Serial/Lot, ตรวจสภาพ, วันหมดอายุ และประวัติผู้ถือครองทุกครั้ง
- ค่า Quota/Lifespan/Reorder Point แก้ไขได้เฉพาะผู้มีสิทธิ์ EHS/คลัง และทุกการแก้ไขต้องมีเหตุผลกับ Audit Log
- รายการที่ Inactive ห้ามสร้างคำขอใหม่ แต่ยังต้องค้นได้ในประวัติเดิม
