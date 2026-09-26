# เปิดแอป PPE SMART ให้คนภายนอกเข้าผ่านลิงก์/QR (ngrok -> Django -> Flutter web)
# วิธีใช้: ดับเบิลคลิก start_public.bat  (ปิดด้วยการกด Enter ในหน้าต่างนี้)
param([int]$Port = 8000)

# โดเมนถาวรฟรีจาก https://dashboard.ngrok.com/domains  เช่น 'ppe-foku.ngrok-free.app'
# ถ้าเว้นว่าง จะได้ลิงก์สุ่มที่เปลี่ยนทุกครั้งที่เปิด (QR ก็เปลี่ยนตาม)
$PublicHost = ''

$Root = $PSScriptRoot
$Backend = Join-Path $Root 'backend'
$Python = Join-Path $Backend '.venv\Scripts\python.exe'
$QrFile = Join-Path $Root 'qr_code.png'

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
    Write-Host 'เปิด ngrok ไม่สำเร็จ ตรวจอินเทอร์เน็ต หรือชื่อโดเมนใน $PublicHost' -ForegroundColor Red
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
& $Python -c "import qrcode, sys; qrcode.make(sys.argv[1], box_size=12, border=3).save(sys.argv[2])" $url $QrFile
Start-Process $QrFile

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host " ลิงก์แอป:  $url" -ForegroundColor Green
Write-Host " QR code:   $QrFile" -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host 'เปิดหน้าต่างนี้ค้างไว้ตลอดที่ให้คนอื่นใช้งาน'
Read-Host 'กด Enter เพื่อปิดระบบ'

Stop-Process $django.Id -ErrorAction SilentlyContinue
Stop-Process $ngrok.Id -ErrorAction SilentlyContinue
Write-Host 'ปิดระบบแล้ว'
