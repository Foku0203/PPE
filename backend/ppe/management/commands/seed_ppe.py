from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from ppe.models import PpeCategory, PpeItem, PpeTranslation, Requisition, Role, StockLot
from ppe.services import approve_requisition, create_requisition, issue_requisition, receive_stock, reserve_and_prepare

DEMO_PASSWORD = 'ChangeMe123!'

# code, category, icon, unit, sizes, requires_serial, returnable, quota, lifespan_days, reorder_point, stock,
# (EN name, EN description), (TH name, TH description), (MY name, MY description)
CATALOG = [
    ('PPE-HLM', PpeCategory.HEAD, 'helmet', 'piece', '', False, False, 1, 730, 20, 60,
     ('Safety Helmet', 'Hard hat with adjustable ratchet suspension for impact and falling-object protection.'),
     ('หมวกนิรภัย', 'หมวกแข็งพร้อมสายรัดปรับขนาด ป้องกันแรงกระแทกและวัตถุตกหล่น'),
     ('ဘေးကင်းရေး ဦးထုပ်', 'ထိခိုက်မှုနှင့် ပြုတ်ကျသောပစ္စည်းများမှ ကာကွယ်ရန် ဦးထုပ်')),
    ('PPE-GOG', PpeCategory.EYE, 'goggles', 'piece', '', False, False, 2, 180, 30, 90,
     ('Safety Glasses', 'Clear polycarbonate lens with side shields, anti-scratch.'),
     ('แว่นตานิรภัย', 'เลนส์โพลีคาร์บอเนตใส มีกระบังด้านข้าง กันรอยขีดข่วน'),
     ('ဘေးကင်းရေး မျက်မှန်', 'ဘေးကာပါသော ကြည်လင်သည့် မျက်မှန်')),
    ('PPE-EAR-P', PpeCategory.HEARING, 'earplug', 'pair', '', False, False, 10, 90, 50, 200,
     ('Corded Earplugs', 'Reusable corded earplugs for noise areas above 85 dB.'),
     ('ที่อุดหูแบบมีสาย', 'ที่อุดหูแบบมีสาย ใช้ซ้ำได้ สำหรับพื้นที่เสียงดังเกิน 85 dB'),
     ('ကြိုးပါ နားဆို့', '85 dB ထက်ကျယ်သော နေရာများအတွက် နားဆို့')),
    ('PPE-EAR-M', PpeCategory.HEARING, 'earmuff', 'piece', '', False, False, 1, 365, 10, 8,
     ('Earmuff', 'Over-the-head earmuff for high-noise work (SNR 35 dB).'),
     ('ที่ครอบหู', 'ที่ครอบหูลดเสียงสำหรับงานเสียงดังมาก (SNR 35 dB)'),
     ('နားဖုံးကိရိယာ', 'ဆူညံသံ အလွန်များသော လုပ်ငန်းအတွက် နားဖုံး')),
    ('PPE-N95', PpeCategory.RESPIRATORY, 'mask', 'piece', '', False, False, 20, 30, 100, 400,
     ('N95 Mask', 'NIOSH N95 particulate respirator. Lot/expiry controlled.'),
     ('หน้ากาก N95', 'หน้ากากกรองฝุ่นละออง N95 มาตรฐาน NIOSH ควบคุม Lot/วันหมดอายุ'),
     ('N95 နှာခေါင်းစည်း', 'NIOSH N95 အမှုန်စစ် နှာခေါင်းစည်း')),
    ('PPE-RSP', PpeCategory.RESPIRATORY, 'respirator', 'set', 'S,M,L', False, False, 1, 365, 10, 30,
     ('Half-face Respirator', 'Half-face respirator with organic vapour cartridges.'),
     ('หน้ากากครึ่งหน้าพร้อมตลับกรอง', 'หน้ากากครึ่งหน้าพร้อมตลับกรองไอระเหยสารอินทรีย์'),
     ('တစ်ဝက်မျက်နှာဖုံး အသက်ရှူကိရိယာ', 'ဓာတ်ငွေ့စစ် ကာထရစ်ပါသော မျက်နှာဖုံး')),
    ('PPE-GLV', PpeCategory.HAND, 'gloves', 'pair', 'S,M,L,XL', False, False, 4, 90, 40, 160,
     ('Cut-resistant Gloves', 'PU-coated cut-resistant gloves, level A4.'),
     ('ถุงมือกันบาด', 'ถุงมือกันบาดเคลือบ PU ระดับ A4'),
     ('ဓားဒဏ်ခံ လက်အိတ်', 'PU အုပ်ထားသော ဓားဒဏ်ခံ လက်အိတ်')),
    ('PPE-GLV-C', PpeCategory.HAND, 'gloves', 'pair', 'M,L', False, False, 12, 30, 100, 600,
     ('Cotton Knitted Gloves', 'General purpose knitted cotton gloves.'),
     ('ถุงมือผ้าฝ้าย', 'ถุงมือผ้าฝ้ายถักสำหรับงานทั่วไป'),
     ('ချည်လက်အိတ်', 'အထွေထွေသုံး ချည်ထိုး လက်အိတ်')),
    ('PPE-GLV-P', PpeCategory.HAND, 'gloves', 'pair', 'M,L,XL', False, False, 4, 60, 30, 120,
     ('PVC Chemical Gloves', 'PVC gloves for chemicals, oils and solvents.'),
     ('ถุงมือ PVC กันสารเคมี', 'ถุงมือ PVC สำหรับงานสารเคมี น้ำมัน และตัวทำละลาย'),
     ('ဓာတုပစ္စည်းကာ PVC လက်အိတ်', 'ဓာတုပစ္စည်း၊ ဆီ နှင့် ပျော်ရည်များအတွက်')),
    ('PPE-BOT', PpeCategory.FOOT, 'boots', 'pair', '38,39,40,41,42,43,44,45', False, False, 1, 365, 20, 80,
     ('Safety Boots', 'Steel toe cap, anti-slip and oil-resistant sole.'),
     ('รองเท้านิรภัย', 'หัวเหล็ก พื้นกันลื่นและทนน้ำมัน'),
     ('ဘေးကင်းရေး ဖိနပ်', 'သံခေါင်းပါ၊ မချော်သော ဖိနပ်')),
    ('PPE-VST', PpeCategory.BODY, 'vest', 'piece', 'M,L,XL,XXL', False, False, 1, 365, 20, 70,
     ('Reflective Safety Vest', 'High-visibility vest with reflective tape.'),
     ('เสื้อสะท้อนแสง', 'เสื้อกั๊กสีสะท้อนแสงพร้อมแถบสะท้อนแสง'),
     ('ရောင်ပြန် ဘေးကင်းရေး အင်္ကျီ', 'အလင်းပြန်တိပ်ပါသော အင်္ကျီ')),
    ('PPE-HAR', PpeCategory.FALL, 'harness', 'set', '', True, True, 1, 1095, 3, 6,
     ('Full Body Harness', 'Full body harness for work at height. Serial and inspection controlled.'),
     ('เข็มขัดนิรภัยเต็มตัว', 'เข็มขัดนิรภัยแบบเต็มตัวสำหรับงานที่สูง ควบคุม Serial และการตรวจสภาพ'),
     ('ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ်', 'အမြင့်တွင် လုပ်ကိုင်ရန် ကိုယ်လုံးကျွတ် ခါးပတ်')),
    ('PPE-LYD', PpeCategory.FALL, 'lanyard', 'set', '', True, True, 1, 1095, 3, 6,
     ('Double Lanyard with Shock Absorber', 'Twin-leg lanyard with energy absorber (EN355).'),
     ('เชือกนิรภัยสองตะขอพร้อมตัวดูดซับแรง', 'เชือกนิรภัยสองขาพร้อมตัวดูดซับแรงกระชาก (EN355)'),
     ('ချိတ်နှစ်ခုပါ ဘေးကင်းကြိုး', 'အရှိန်စုပ်ကိရိယာပါ ကြိုး (EN355)')),
]

# Fall protection: every request needs special approval (Supervisor + EHS), whoever asks.
ALWAYS_SPECIAL = {'PPE-HAR', 'PPE-LYD'}

CATALOG_ZH = {
    'PPE-HLM': ('安全帽', '带可调节棘轮的安全帽，防冲击和防坠落物。'),
    'PPE-GOG': ('安全眼镜', '透明聚碳酸酯镜片，带侧护罩，防刮擦。'),
    'PPE-EAR-P': ('带线耳塞', '可重复使用的带线耳塞，适用于 85 分贝以上噪声区域。'),
    'PPE-EAR-M': ('防噪音耳罩', '头戴式耳罩，用于高噪声作业（SNR 35 dB）。'),
    'PPE-N95': ('N95 口罩', 'NIOSH N95 颗粒物防护口罩，按批次/有效期管理。'),
    'PPE-RSP': ('半面罩呼吸器', '配有机蒸气滤毒盒的半面罩呼吸器。'),
    'PPE-GLV': ('防割手套', 'PU 涂层防割手套，A4 级。'),
    'PPE-GLV-C': ('棉纱手套', '通用针织棉手套。'),
    'PPE-GLV-P': ('PVC 防化手套', '适用于化学品、油类和溶剂的 PVC 手套。'),
    'PPE-BOT': ('安全鞋', '钢头，防滑耐油鞋底。'),
    'PPE-VST': ('反光背心', '带反光条的高可视背心。'),
    'PPE-HAR': ('全身式安全带', '高处作业用全身式安全带，按序列号和检查管理。'),
    'PPE-LYD': ('双钩缓冲安全绳', '带缓冲器的双腿安全绳（EN355）。'),
}

USERS = [
    # employee_id, username, display name, role, department, supervisor employee_id
    ('ADMIN001', 'admin', 'System Admin', Role.ADMIN, 'IT', None),
    ('EHS001', 'ehs', 'Safety Officer (EHS)', Role.EHS, 'EHS', None),
    ('STORE001', 'store', 'Store Keeper', Role.STORE_KEEPER, 'Warehouse', None),
    ('SUP001', 'supervisor', 'Plant Supervisor', Role.SUPERVISOR, 'Production', None),
    ('EMP001', 'worker', 'Somchai Worker', Role.WORKER, 'Production', 'SUP001'),
    ('EMP002', 'worker2', 'Aung Kyaw', Role.WORKER, 'Production', 'SUP001'),
]


class Command(BaseCommand):
    help = 'Create demo PPE catalog, users for every role, stock and sample requisitions.'

    def add_arguments(self, parser):
        parser.add_argument('--no-requests', action='store_true', help='Do not create sample requisitions.')

    def handle(self, *args, **options):
        User = get_user_model()
        users = {}
        for employee_id, username, name, role, department, supervisor_id in USERS:
            user, _ = User.objects.get_or_create(employee_id=employee_id, defaults={'username': username, 'display_name': name, 'role': role})
            user.display_name, user.role, user.department = name, role, department
            user.supervisor = users.get(supervisor_id)
            user.is_staff = user.is_superuser = role == Role.ADMIN
            user.set_password(DEMO_PASSWORD)
            user.save()
            users[employee_id] = user

        store = users['STORE001']
        now = timezone.now()
        items = {}
        for (code, category, icon, unit, sizes, serial, returnable, quota, lifespan, reorder, stock, en, th, my) in CATALOG:
            item, _ = PpeItem.objects.update_or_create(code=code, defaults={
                'category': category, 'icon_key': icon, 'unit': unit, 'sizes': sizes, 'requires_serial': serial, 'is_returnable': returnable,
                'quota': quota, 'lifespan_days': lifespan, 'reorder_point': reorder, 'active': True,
                'always_special_approval': code in ALWAYS_SPECIAL})
            for locale, (name, description) in [('EN', en), ('TH', th), ('MY', my), ('ZH', CATALOG_ZH[code])]:
                PpeTranslation.objects.update_or_create(ppe_item=item, locale=locale, defaults={'name': name, 'description': description})
            items[code] = item
            if StockLot.objects.filter(ppe_item=item).exists():
                continue
            if serial:
                receive_stock(ppe_item=item, actor=store, quantity=stock, lot_number=f'{code}-LOT-01', supplier='Demo Supplier',
                              serial_numbers=[f'{code[4:]}-{i:04d}' for i in range(1, stock + 1)], expiry_at=now + timedelta(days=365 * 5))
            elif code == 'PPE-N95':
                receive_stock(ppe_item=item, actor=store, quantity=40, lot_number='N95-LOT-EXP', supplier='Demo Supplier', expiry_at=now + timedelta(days=20))
                receive_stock(ppe_item=item, actor=store, quantity=stock - 40, lot_number='N95-LOT-02', supplier='Demo Supplier', expiry_at=now + timedelta(days=365))
            else:
                receive_stock(ppe_item=item, actor=store, quantity=stock, lot_number=f'{code}-LOT-01', supplier='Demo Supplier')

        if not options['no_requests'] and not Requisition.objects.exists():
            self._sample_requests(users, items)

        self.stdout.write(self.style.SUCCESS(
            f'PPE demo data seeded: {len(items)} items. Logins (password {DEMO_PASSWORD}): ' + ', '.join(f'{u[0]} ({u[3]})' for u in USERS)))

    def _sample_requests(self, users, items):
        worker, worker2, supervisor, store = users['EMP001'], users['EMP002'], users['SUP001'], users['STORE001']
        # Completed history so "My PPE" and lifespan checks have data.
        done = create_requisition(requester=worker, client_request_id='seed-1', items=[
            {'ppe_item_id': items['PPE-BOT'].id, 'quantity': 1, 'reason': 'NEW_EMPLOYEE', 'size': '42'},
            {'ppe_item_id': items['PPE-VST'].id, 'quantity': 1, 'reason': 'NEW_EMPLOYEE', 'size': 'L'}])
        approve_requisition(requisition=done, approver=supervisor, decision='APPROVED')
        reserve_and_prepare(requisition_id=done.id, actor=store)
        issue_requisition(requisition_id=done.id, actor=store)
        # Ready for pickup (worker 2).
        ready = create_requisition(requester=worker2, client_request_id='seed-2', items=[
            {'ppe_item_id': items['PPE-GLV'].id, 'quantity': 2, 'reason': 'DAMAGED', 'size': 'L'}])
        approve_requisition(requisition=ready, approver=supervisor, decision='APPROVED')
        reserve_and_prepare(requisition_id=ready.id, actor=store)
        # Approved, waiting for store.
        approved = create_requisition(requester=worker2, client_request_id='seed-3', items=[
            {'ppe_item_id': items['PPE-HLM'].id, 'quantity': 1, 'reason': 'DAMAGED'}])
        approve_requisition(requisition=approved, approver=supervisor, decision='APPROVED')
        # Pending supervisor approval.
        create_requisition(requester=worker, client_request_id='seed-4', items=[
            {'ppe_item_id': items['PPE-GOG'].id, 'quantity': 1, 'reason': 'LOST'},
            {'ppe_item_id': items['PPE-EAR-P'].id, 'quantity': 5, 'reason': 'LIFESPAN_EXPIRED'}])
        # Special approval (early replacement of boots issued above).
        create_requisition(requester=worker, client_request_id='seed-5', special_reason='Sole cracked after chemical spill.', items=[
            {'ppe_item_id': items['PPE-BOT'].id, 'quantity': 1, 'reason': 'DAMAGED', 'size': '42'}])
