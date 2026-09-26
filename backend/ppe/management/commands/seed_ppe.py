from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from ppe.models import PpeItem, PpeTranslation, Role, StockLot

CATALOG = [
    ('PPE-HLM', 'helmet', 'piece', 'Safety Helmet', 'หมวกนิรภัย', 'ဘေးကင်း ဦးထုပ်', 12, 730, 50),
    ('PPE-BOT', 'boots', 'pair', 'Safety Boots', 'รองเท้านิรภัย', 'လုံခြုံရေးဖိနပ်', 1, 365, 40),
    ('PPE-GOG', 'goggles', 'piece', 'Safety Goggles', 'แว่นตานิรภัย', 'အကာအကွယ်မျက်မှန်', 2, 180, 30),
    ('PPE-VST', 'vest', 'piece', 'Safety Vest', 'เสื้อสะท้อนแสง', 'ရောင်ပြန်အင်္ကျ', 1, 365, 30),
    ('PPE-HAR', 'harness', 'set', 'Safety Harness', 'สายรัดนิรภัย', 'ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ်', 1, 1095, 15),
    ('PPE-GLV', 'gloves', 'pair', 'Safety Gloves', 'ถุงมือนิรภัย', 'ဘေးကင်းလုံခြုံရေး လက်အိတ်', 10, 90, 100),
    ('PPE-EAR-P', 'earplug', 'pair', 'Earplug', 'ที่อุดหู', 'နားဆို့', 10, 90, 50),
    ('PPE-EAR-M', 'earmuff', 'piece', 'Earmuff', 'ที่ครอบหู', 'နားဖုံးကိရိယာ', 1, 365, 20),
    ('PPE-N95', 'mask', 'piece', 'N95 Mask', 'หน้ากาก N95', 'N95 အသက်ရှူကာမျက်နှာဖုံး', 20, 30, 100),
]


class Command(BaseCommand):
    help = 'Create demo PPE catalog, users, and stock.'

    def handle(self, *args, **options):
        User = get_user_model()
        admin, _ = User.objects.get_or_create(employee_id='ADMIN001', defaults={'username': 'admin', 'display_name': 'EHS Admin', 'role': Role.ADMIN, 'is_staff': True, 'is_superuser': True})
        admin.set_password('ChangeMe123!')
        admin.save()
        supervisor, _ = User.objects.get_or_create(employee_id='SUP001', defaults={'username': 'supervisor', 'display_name': 'Plant Supervisor', 'role': Role.SUPERVISOR})
        worker, _ = User.objects.get_or_create(employee_id='EMP001', defaults={'username': 'worker', 'display_name': 'Demo Worker', 'role': Role.WORKER, 'supervisor': supervisor})
        worker.supervisor = supervisor
        worker.save(update_fields=['supervisor'])
        for code, icon, unit, en, th, my, quota, lifespan, reorder in CATALOG:
            item, _ = PpeItem.objects.update_or_create(code=code, defaults={'icon_key': icon, 'unit': unit, 'quota': quota, 'lifespan_days': lifespan, 'reorder_point': reorder})
            for locale, name in [('EN', en), ('TH', th), ('MY', my)]:
                PpeTranslation.objects.update_or_create(ppe_item=item, locale=locale, defaults={'name': name})
            if not StockLot.objects.filter(ppe_item=item).exists():
                quantity = 12 if code == 'PPE-HAR' else max(reorder * 3, 50)
                StockLot.objects.create(ppe_item=item, lot_number=f'{code}-LOT-01', serial_number=f'{code}-SER-001' if code == 'PPE-HAR' else None, quantity=quantity)
        self.stdout.write(self.style.SUCCESS('PPE demo data seeded. Admin login: ADMIN001 / ChangeMe123!'))
