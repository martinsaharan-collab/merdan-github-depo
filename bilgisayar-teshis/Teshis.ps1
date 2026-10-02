# Bilgisayar Yavaşlık Teşhis Betiği (Windows 10/11)
# Yalnızca OKUMA yapar; sistemde hiçbir ayarı değiştirmez.
# Çalıştırma: PowerShell'i "Yönetici olarak çalıştır" ile açın, sonra:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\Teshis.ps1
# Rapor masaüstüne "Teshis-Raporu.txt" olarak kaydedilir.

$ErrorActionPreference = 'SilentlyContinue'
$rapor = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Teshis-Raporu.txt'
$bulgular = New-Object System.Collections.Generic.List[string]

function Baslik($metin) { "`n===== $metin =====" }
function Bulgu($seviye, $metin) { $bulgular.Add("[$seviye] $metin") }

$cikti = & {
    Baslik 'SISTEM'
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $uptime = (Get-Date) - $os.LastBootUpTime
    $ramGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $bosGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    "İşletim sistemi : $($os.Caption) ($($os.Version))"
    "İşlemci         : $($cpu.Name)"
    "RAM             : $ramGB GB (boş: $bosGB GB)"
    "Açık kalma süresi: $([int]$uptime.TotalDays) gün $($uptime.Hours) saat"

    if ($ramGB -lt 8)  { Bulgu 'KRITIK' "RAM $ramGB GB. Windows 10/11 + tarayıcı + Office için en az 8 GB, tercihen 16 GB gerekir." }
    if ($bosGB / $ramGB -lt 0.15) { Bulgu 'UYARI' "Boş RAM %15'in altında ($bosGB GB). Bellek darboğazı var." }
    if ($uptime.TotalDays -gt 7) { Bulgu 'UYARI' "Bilgisayar $([int]$uptime.TotalDays) gündür yeniden başlatılmamış. 'Hızlı başlatma' nedeniyle Kapat tam kapatmaz; Yeniden Başlat kullanın." }

    Baslik 'ANLIK YÜK (5 sn ortalama)'
    # Sayaç adları Türkçe Windows'ta yerelleştirildiği için Get-Counter yerine CIM sınıfları kullanılır
    $cpuOrn = @(); $diskOrn = @()
    1..5 | ForEach-Object {
        $cpuOrn  += (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
        $diskOrn += [math]::Min(100, (Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'").PercentDiskTime)
        Start-Sleep -Seconds 1
    }
    $cpuYuk  = [math]::Round(($cpuOrn  | Measure-Object -Average).Average, 0)
    $diskYuk = [math]::Round(($diskOrn | Measure-Object -Average).Average, 0)
    "İşlemci kullanımı: %$cpuYuk"
    "Disk meşguliyeti : %$diskYuk"
    if ($cpuYuk -gt 70)  { Bulgu 'UYARI' "Boşta iken işlemci %$cpuYuk. Arka planda yoğun bir işlem var (aşağıdaki listeye bakın)." }
    if ($diskYuk -gt 80) { Bulgu 'KRITIK' "Disk %$diskYuk meşgul. Tipik HDD darboğazı veya arka plan güncelleme/tarama." }

    Baslik 'EN ÇOK RAM KULLANAN 10 İŞLEM'
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 |
        Format-Table @{n='İşlem';e={$_.ProcessName}}, @{n='RAM (MB)';e={[math]::Round($_.WorkingSet64/1MB)}} -AutoSize | Out-String

    Baslik 'EN ÇOK İŞLEMCİ ZAMANI HARCAYAN 10 İŞLEM'
    Get-Process | Where-Object CPU | Sort-Object CPU -Descending | Select-Object -First 10 |
        Format-Table @{n='İşlem';e={$_.ProcessName}}, @{n='CPU (sn)';e={[math]::Round($_.CPU)}} -AutoSize | Out-String

    Baslik 'DİSKLER'
    foreach ($pd in Get-PhysicalDisk) {
        "$($pd.FriendlyName) | Tür: $($pd.MediaType) | Sağlık: $($pd.HealthStatus) | $([math]::Round($pd.Size/1GB)) GB"
        if ($pd.MediaType -eq 'HDD') { Bulgu 'KRITIK' "Sistemde mekanik disk (HDD) var: $($pd.FriendlyName). Yavaşlığın en yaygın nedeni; SSD'ye geçiş en yüksek etkili iyileştirmedir." }
        if ($pd.HealthStatus -and $pd.HealthStatus -ne 'Healthy') { Bulgu 'KRITIK' "Disk sağlığı '$($pd.HealthStatus)': $($pd.FriendlyName). Hemen yedek alın." }
    }
    foreach ($v in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3') {
        $bos = [math]::Round($v.FreeSpace / 1GB, 1); $top = [math]::Round($v.Size / 1GB, 1)
        $oran = if ($top) { [math]::Round(100 * $bos / $top) } else { 0 }
        "$($v.DeviceID) toplam $top GB, boş $bos GB (%$oran)"
        if ($oran -lt 15) { Bulgu 'KRITIK' "$($v.DeviceID) sürücüsünde boş alan %$oran. En az %15-20 boş alan gerekir." }
    }

    Baslik 'GEÇİCİ DOSYALAR'
    $tempMB = [math]::Round(((Get-ChildItem $env:TEMP -Recurse -Force | Measure-Object Length -Sum).Sum) / 1MB)
    "Kullanıcı TEMP klasörü: $tempMB MB"
    if ($tempMB -gt 2048) { Bulgu 'BILGI' "TEMP klasörü $tempMB MB. Disk Temizleme / Depolama Algılayıcı ile temizlenebilir." }

    Baslik 'BAŞLANGIÇTA ÇALIŞAN PROGRAMLAR'
    $baslangic = Get-CimInstance Win32_StartupCommand
    $baslangic | Format-Table @{n='Program';e={$_.Name}}, @{n='Konum';e={$_.Location}} -AutoSize | Out-String
    if (@($baslangic).Count -gt 10) { Bulgu 'UYARI' "Başlangıçta $(@($baslangic).Count) program açılıyor. Görev Yöneticisi > Başlangıç sekmesinden gereksizleri devre dışı bırakın." }

    Baslik 'GÜÇ PLANI'
    $guc = (powercfg /getactivescheme) -join ' '
    $guc
    if ($guc -match 'Power saver|Güç tasarrufu') { Bulgu 'UYARI' "Güç tasarrufu planı aktif; işlemci kısılıyor. 'Dengeli' veya 'Yüksek performans' seçin (dizüstünde adaptör takılıyken)." }

    Baslik 'GÜVENLİK / ANTİVİRÜS'
    $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
    $av | ForEach-Object { "Antivirüs: $($_.displayName)" }
    if (@($av).Count -gt 1) { Bulgu 'UYARI' "Birden fazla antivirüs kayıtlı ($((@($av).displayName) -join ', ')). Aynı anda iki gerçek zamanlı tarayıcı sistemi ciddi yavaşlatır; birini kaldırın." }

    Baslik 'BEKLEYEN YENİDEN BAŞLATMA'
    $bekleyen = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
                (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
    "Yeniden başlatma bekleniyor: $bekleyen"
    if ($bekleyen) { Bulgu 'UYARI' "Windows Update yeniden başlatma bekliyor. Arka planda güncelleme işlemleri sürüyor olabilir." }

    Baslik 'SON 7 GÜNDE DİSK HATALARI (Sistem günlüğü)'
    $diskHata = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='disk','Ntfs','storahci','stornvme'; Level=2,3; StartTime=(Get-Date).AddDays(-7)}
    "Kayıt sayısı: $(@($diskHata).Count)"
    if (@($diskHata).Count -gt 0) { Bulgu 'KRITIK' "Son 7 günde $(@($diskHata).Count) disk hata/uyarı kaydı var. Disk arızası başlangıcı olabilir; yedek alın, CrystalDiskInfo ile SMART kontrol edin." }
}

$ozet = @('', '##########  ÖZET BULGULAR  ##########')
$ozet += if ($bulgular.Count) { $bulgular } else { 'Belirgin bir sorun tespit edilmedi. Sorun sürüyorsa raporu paylaşın.' }

($cikti + $ozet) | Out-File -FilePath $rapor -Encoding utf8
$ozet | Write-Host
Write-Host "`nTam rapor: $rapor" -ForegroundColor Green
