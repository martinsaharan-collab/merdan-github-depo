# Bilgisayar Yavaşlığı: Teşhis ve Tavsiye Listesi

## 1. Teşhis (5 dakika)

1. `Teshis.ps1` dosyasını bilgisayara indirin.
2. Başlat > "PowerShell" > sağ tık > **Yönetici olarak çalıştır**.
3. Dosyanın bulunduğu klasöre geçip çalıştırın:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\Teshis.ps1
   ```
4. Masaüstünde oluşan `Teshis-Raporu.txt` dosyasının **ÖZET BULGULAR** bölümüne bakın.

Betik yalnızca okuma yapar; hiçbir ayarı değiştirmez.

## 2. Olası nedenler ve etkisi

| # | Neden | Belirti | Etki |
|---|-------|---------|------|
| 1 | Mekanik disk (HDD) | Açılış 2+ dk, Görev Yöneticisi'nde Disk %100 | **Çok yüksek** |
| 2 | Yetersiz RAM (≤ 8 GB) | Çok sekmeli tarayıcı + Excel/Power BI ile donma | **Yüksek** |
| 3 | Disk dolu (< %15 boş) | Genel yavaşlık, güncelleme hataları | Yüksek |
| 4 | Başlangıç programları | Açılış sonrası ilk 5-10 dk ağırlık | Orta |
| 5 | Çift antivirüs / ağır güvenlik yazılımı | Dosya açma/kopyalamada gecikme | Orta-Yüksek |
| 6 | Bekleyen Windows Update | Arka planda disk/CPU kullanımı | Orta |
| 7 | Uzun süre yeniden başlatılmama | Bellek sızıntısı, yavaşlayan uygulamalar | Orta |
| 8 | Güç tasarrufu planı | İşlemci kısılması (özellikle dizüstü) | Orta |
| 9 | Toz / termal kısılma | Fan sesi, ısınma, yük altında ani yavaşlama | Orta-Yüksek |
| 10 | Kötü amaçlı yazılım / reklam yazılımı | Tanımadığınız işlemler, tarayıcı açılış sayfası değişimi | Yüksek |
| 11 | Arızalanmaya başlayan disk | Takılmalar, Sistem günlüğünde disk hataları | **Kritik (veri kaybı riski)** |

## 3. Tavsiye listesi (öncelik sırasıyla)

### A. Ücretsiz, hemen (≈ 30 dk)

- [ ] **Yeniden Başlat** (Kapat değil). Windows "Hızlı başlatma" nedeniyle Kapat tam sıfırlamaz.
- [ ] **Görev Yöneticisi** (Ctrl+Shift+Esc) > **Başlangıç** sekmesi: OneDrive dışındaki gereksizleri *Devre dışı bırak* (güncelleyiciler, Spotify, Teams otomatik başlatma vb.).
- [ ] **Ayarlar > Sistem > Depolama > Depolama Algılayıcı**: aç; *Geçici dosyalar* temizle.
- [ ] **Ayarlar > Windows Update**: bekleyen güncellemeleri tamamla, yeniden başlat.
- [ ] **Güç planı**: Ayarlar > Sistem > Güç > *En iyi performans* (dizüstünde şarj takılıyken).
- [ ] **Tarayıcı**: kullanılmayan uzantıları kaldır; sekme sayısını azalt (Chrome/Edge'de *Bellek tasarrufu* aç).
- [ ] **Tek antivirüs**: Windows Defender yeterlidir; ek antivirüs varsa birini kaldır. (Şirket bilgisayarıysa IT'ye danışın.)

### B. Güvenlik ve sağlık kontrolü

- [ ] Windows Güvenliği > Virüs ve tehdit koruması > **Tam tarama** (veya *Microsoft Defender Çevrimdışı tarama*).
- [ ] **CrystalDiskInfo** (ücretsiz) ile disk SMART durumu: *Dikkat/Kötü* çıkarsa **önce yedek alın**.
- [ ] **HWiNFO** ile yük altında CPU sıcaklığı: sürekli 90 °C üzeri → fan/termal macun temizliği.

### C. Donanım yükseltme (en yüksek getiri/maliyet)

| Yükseltme | Yaklaşık maliyet | Beklenen kazanç |
|-----------|------------------|-----------------|
| HDD → SATA/NVMe SSD (500 GB-1 TB) | Düşük | Açılış 2-3 dk → ~20 sn; genel hız 3-5 kat |
| RAM 8 → 16 GB | Düşük | Power BI, Excel, çok sekmeli tarayıcıda donmaların bitmesi |
| Bakım (toz + termal macun) | Düşük | Termal kısılmanın ortadan kalkması |

Not: Power BI Desktop ve çok sayıda tarayıcı sekmesi için **16 GB RAM + SSD** pratik asgari yapılandırmadır.

### D. Son çare

- [ ] Ayarlar > Sistem > Kurtarma > **Bu bilgisayarı sıfırla** (*Dosyalarımı koru*). Öncesinde yedek alın.
- [ ] Cihaz 7+ yaşında ve işlemci 4 çekirdekten azsa yükseltme yerine yenileme daha rasyoneldir.

## 4. Raporu paylaşma

`Teshis-Raporu.txt` içeriğini paylaşırsanız bulgulara özel, net bir yol haritası çıkarılabilir.
