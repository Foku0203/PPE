from django.db import migrations, models


def flag_fall_protection(apps, schema_editor):
    apps.get_model('ppe', 'PpeItem').objects.filter(code__in=['PPE-HAR', 'PPE-LYD']).update(always_special_approval=True)


class Migration(migrations.Migration):

    dependencies = [
        ('ppe', '0004_catalog_fields_comments'),
    ]

    operations = [
        migrations.AddField(
            model_name='ppeitem',
            name='always_special_approval',
            field=models.BooleanField(default=False, help_text='Every request needs special approval (Supervisor + EHS), e.g. fall protection.'),
        ),
        migrations.RunPython(flag_fall_protection, migrations.RunPython.noop),
    ]
