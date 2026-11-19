---
name: daily-done
description: Biten bir iş için projenin wiki/daily-done/YYYY-MM.md dosyasına tek satırlık kaydı doğru biçimde, Türkiye saatiyle ekler. Kullanıcı "daily done yaz", "bunu kaydet", "/daily-done" dediğinde ya da bir iş "bitti" tanımına göre kapanırken kullan.
argument-hint: "[konu] [özet]"
---

# Daily done satırı

Kuralın kaynağı: `docs/standards/standards/wiki.md` → "Daily done". Bu dosyayla
çelişirse orası doğrudur.

## Adımlar

1. **Saat ve tarih:** `TZ=Europe/Istanbul date '+%Y-%m-%d %H:%M'` (bulut ortamı UTC'dir;
   yerel makinede de bu komutu kullan).
2. **Dosya:** `wiki/daily-done/<YYYY-MM>.md`. Yoksa `wiki/daily-done/_template.md`'den
   (o da yoksa `docs/standards/templates/wiki/daily-done/_template.md`) kopyala ve
   `{{date:…}}` yer tutucularını gerçek değerle doldur.
3. **Gün başlığı:** `## YYYY-MM-DD` yoksa dosyanın sonuna ekle (günler eskiden yeniye).
4. **Satır** — o günün başlığının altına, en sona:

   ```markdown
   - SS:DD · **Konu (2–6 kelime)** · `klasör/` · Bir cümle: ne değişti. → [günlük](../gunluk/<dosya>.md)
   ```

   - **Konu:** kullanıcı verdiyse onu kullan; vermediyse işin özünden çıkar.
   - **Klasör:** `git diff --name-only` (ve son commit'ler) hangi alt proje
     klasörlerine dokunduğunu söyler (`backend/`, `client/`, `ios/`…); birden fazlaysa
     virgülle; yalnızca kök dosyalarsa `/`.
   - **Özet:** nasıl değil ne değişti; bir cümle.
   - **Günlük linki:** bu iş için `wiki/gunluk/` kaydı varsa ekle, yoksa yazma.
5. Yarım kalan iş için satır yazma. Bir oturumda birden çok iş bittiyse her biri ayrı satır.

## Dikkat

- Satırları **CLAUDE.md'ye yazma** (her oturumda yüklenir, bağlamı şişirir).
- Prettier markdown'ı biçimliyorsa satır içinde ters eğik çizgiyle kaçışlı backtick
  (`` \` ``) kullanma; birleştirip satırları bozabiliyor.
- Proje wiki'yi farklı şemayla tutuyor olsa bile daily-done dosyası standart biçimdedir.
