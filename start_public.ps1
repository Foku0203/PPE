# เปิดแอป PPE SMART ให้คนภายนอกเข้าผ่านลิงก์/QR (ngrok -> Django -> Flutter web)
# วิธีใช้: ดับเบิลคลิก start_public.bat  (ปิดด้วยการกด Enter ในหน้าต่างนี้)
# -Domain: ใช้โดเมนนี้แทนค่าที่บันทึกไว้ ('random' = ลิงก์สุ่ม)
param([int]$Port = 8000, [string]$Domain = '')

$Root = $PSScriptRoot
$Backend = Join-Path $Root 'backend'
$Python = Join-Path $Root '.venv\Scripts\python.exe'
$QrFile = Join-Path $Root 'qr_code.png'

# โดเมนถาวรฟรีจาก https://dashboard.ngrok.com/domains ถามครั้งแรกครั้งเดียวแล้วจำไว้ในไฟล์นี้
# (ลบไฟล์นี้ถ้าจะเปลี่ยนโดเมน) ถ้าไม่มีโดเมน จะได้ลิงก์สุ่มที่เปลี่ยนทุกครั้งที่เปิด
$DomainFile = Join-Path $Root 'public_domain.txt'
if (-not $Domain) {
    if (Test-Path $DomainFile) {
        $Domain = (Get-Content $DomainFile -Raw).Trim()
    } else {
        Write-Host 'ยังไม่ได้ตั้งโดเมนถาวร (ลิงก์/QR จะเปลี่ยนทุกครั้งที่เปิด)' -ForegroundColor Yellow
        Write-Host 'สร้างโดเมนฟรีได้ที่ https://dashboard.ngrok.com/domains แล้ววางชื่อโดเมนที่นี่'
        $answer = Read-Host 'ชื่อโดเมน (เช่น abc-def.ngrok-free.app) หรือกด Enter เพื่อใช้ลิงก์สุ่ม'
        $Domain = ($answer -replace '^\s*https?://', '' -replace '/.*$', '').Trim()
        if ($Domain) { Set-Content $DomainFile $Domain -Encoding ascii; Write-Host "บันทึกโดเมนแล้ว: $Domain" -ForegroundColor Green }
    }
}
$PublicHost = if ($Domain -eq 'random') { '' } else { $Domain }

# กันคอมเข้าโหมด Sleep เฉพาะตอนที่สคริปต์นี้เปิดอยู่ (ปิดสคริปต์แล้วกลับเป็นค่าปกติ)
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$ES_CONTINUOUS = [uint32]'0x80000000'
$ES_SYSTEM_REQUIRED = [uint32]1

if (-not (Test-Path (Join-Path $Root 'ppe_mobile_app\build\web\index.html'))) {
    Write-Host 'ยังไม่มีไฟล์แอปเวอร์ชันเว็บ ให้รัน: cd ppe_mobile_app; flutter build web --release' -ForegroundColor Red
    Read-Host 'กด Enter เพื่อปิด'; exit 1
}
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "พอร์ต $Port ถูกใช้อยู่ (อาจเปิด Django ค้างไว้) ให้ปิดก่อนแล้วลองใหม่" -ForegroundColor Red
    Read-Host 'กด Enter เพื่อปิด'; exit 1
}

# SECRET_KEY คงที่ข้ามการเปิดแต่ละครั้ง ผู้ใช้จะได้ไม่หลุดล็อกอินทุกครั้งที่รีสตาร์ท
$SecretFile = Join-Path $Backend '.public_secret'
if (-not (Test-Path $SecretFile)) {
    & $Python -c "import secrets; print(secrets.token_urlsafe(50))" | Out-File $SecretFile -Encoding ascii
}

Write-Host '1/3 กำลังเปิดทันเนล ngrok...' -ForegroundColor Cyan
$ngrokArgs = @('http', "$Port", '--log', 'stdout')
if ($PublicHost) { $ngrokArgs += "--url=https://$PublicHost" }
$ngrok = Start-Process ngrok -ArgumentList $ngrokArgs -WindowStyle Hidden -PassThru
$url = $null
foreach ($i in 1..20) {
    Start-Sleep 1
    try { $url = ((Invoke-RestMethod http://127.0.0.1:4040/api/tunnels).tunnels | Where-Object proto -eq 'https' | Select-Object -First 1).public_url } catch {}
    if ($url) { break }
}
if (-not $url) {
    Stop-Process $ngrok.Id -ErrorAction SilentlyContinue
    Write-Host 'เปิด ngrok ไม่สำเร็จ ตรวจอินเทอร์เน็ต หรือชื่อโดเมน (ลบไฟล์ public_domain.txt แล้วเปิดใหม่เพื่อใส่โดเมนใหม่)' -ForegroundColor Red
    Read-Host 'กด Enter เพื่อปิด'; exit 1
}
$hostName = ([Uri]$url).Host

Write-Host '2/3 กำลังเปิดเซิร์ฟเวอร์...' -ForegroundColor Cyan
$env:DJANGO_DEBUG = 'False'
$env:PUBLIC_HOST = $hostName
$env:DJANGO_SECRET_KEY = (Get-Content $SecretFile -Raw).Trim()
Push-Location $Backend
& $Python manage.py migrate --noinput | Out-Null
# --insecure: ให้ runserver เสิร์ฟไฟล์ static ของหน้า admin แม้ปิด DEBUG
$django = Start-Process $Python -ArgumentList 'manage.py', 'runserver', "127.0.0.1:$Port", '--insecure', '--noreload' -WindowStyle Hidden -PassThru
Pop-Location

Write-Host '3/3 กำลังสร้าง QR code...' -ForegroundColor Cyan
$makeQr = "import qrcode, sys; qrcode.make(sys.argv[1], box_size=12, border=3).save(sys.argv[2])"
& $Python -c $makeQr $url $QrFile 2>$null
if ($LASTEXITCODE -ne 0) {
    # qr_code.png is locked (usually still open in the image viewer): write a fresh file instead of keeping a stale QR.
    $QrFile = Join-Path $Root ("qr_code_{0:yyyyMMdd_HHmmss}.png" -f (Get-Date))
    & $Python -c $makeQr $url $QrFile
    Write-Host "qr_code.png ถูกเปิดค้างอยู่ จึงบันทึก QR ใหม่เป็น $QrFile" -ForegroundColor Yellow
}
Start-Process $QrFile

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host " ลิงก์แอป:  $url" -ForegroundColor Green
Write-Host " QR code:   $QrFile" -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
if (-not $PublicHost) { Write-Host ' * ลิงก์นี้เป็นแบบสุ่ม เปิดใหม่ครั้งหน้าลิงก์/QR จะเปลี่ยน' -ForegroundColor Yellow }
[Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED) | Out-Null
Write-Host ' * ระหว่างนี้คอมจะไม่เข้าโหมด Sleep (จอดับได้ตามปกติ)'
Write-Host 'เปิดหน้าต่างนี้ค้างไว้ตลอดที่ให้คนอื่นใช้งาน'
Read-Host 'กด Enter เพื่อปิดระบบ'

[Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
Stop-Process $django.Id -ErrorAction SilentlyContinue
Stop-Process $ngrok.Id -ErrorAction SilentlyContinue
Write-Host 'ปิดระบบแล้ว'
