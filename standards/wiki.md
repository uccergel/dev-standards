# Wiki disiplini

Her projenin kökünde `wiki/` klasörü projenin yaşayan hafızasıdır. Claude Code dahil tüm
geliştirme oturumları onu okur ve besler. Kod ile wiki çeliştiği an wiki güncellenir:
güncel olmayan doküman, olmayan dokümandan kötüdür.

Wiki'ler Obsidian'da merkezi bir vault üzerinden de okunur ve yazılır (kurulum:
`obsidian/README.md`). Bu yüzden aşağıdaki biçim kuralları hem GitHub'da hem Obsidian'da
düzgün görünmek için vardır.

## Klasörler

| Klasör           | İçerik                                                     | Ne zaman yazılır |
|------------------|------------------------------------------------------------|------------------|
| `daily-done/`    | Biten her iş için tek satır: saat, konu, klasör, özet      | Her iş bittiğinde (bkz. "Daily done") |
| `gunluk/`        | Oturum günlüğü: yapılan, karar + gerekçe, sonraki adım     | Her anlamlı oturumun sonunda |
| `hata-yonetimi/` | Hata kaydı: belirti → kök neden → çözüm → önlem            | Çözümü 15 dk'yı aşan her hatada; aynı hata ikinci kez yaşandıysa |
| `referans/`      | Tasarım dokümanları, API sözleşmesi, mimari kararlar, güvenlik denetimi | Tasarım değiştiğinde |
| `roadmaps/`      | Yol haritası ve faz planları (checkbox'lı)                 | Faz başında; tamamlandıkça işaretlenir |
| `scripts/`       | Script ve management command dokümanı                      | Yeni script/command eklendiğinde |
| `servisler/`     | Servis katmanı: sorumluluk, formül, invariant, test kapsamı | Yeni servis eklendiğinde / değiştiğinde |

Her klasörde kopyalanarak kullanılacak bir `_template.md` vardır (kaynak: bu reponun
`templates/wiki/`). Şablonlar Obsidian'ın Templates eklentisiyle de kullanılabilir:
`{{date:YYYY-MM-DD}}` gibi yer tutucuları Obsidian kendisi doldurur; elle kopyalarken
gerçek değerle değiştir. `_template.md` dosyaları düzenlenmez.

## Daily done

Hızlı bakış kaydı: "bugün hangi projede ne bitti?" sorusunun tek satırlık cevabı.
Ayrıntılar (kararlar, gerekçeler) `gunluk/`'te kalır; daily done onun yerini tutmaz.

- **Dosya:** `wiki/daily-done/YYYY-MM.md`, ay başına bir dosya. Ay içinde ilk kayıtta
  `templates/wiki/daily-done/_template.md`'den açılır.
- **Ne zaman:** Biten her iş için bir satır, iş bittiği anda. Bir oturumda üç ayrı iş
  bittiyse üç satır. Yarım kalan iş yazılmaz.
- **Yer:** Günün `## YYYY-MM-DD` başlığının altına, saat sırasıyla en alta eklenir. Başlık
  yoksa ayın sonuna açılır. Günler eskiden yeniye sıralıdır.
- **Biçim:**
  ```markdown
  - 21:40 · **Ortak standartlara bağlanma** · `/` · Kök CLAUDE.md artık dev-standards'ı import ediyor. → [günlük](../gunluk/2026-11-18-ortak-standartlar.md)
  ```
  - **Saat:** `SS:DD`, Türkiye saati. Bulut ortamı UTC'de çalışır, saati
    `TZ=Europe/Istanbul date +%H:%M` ile al.
  - **Konu:** Kalın, 2–6 kelime.
  - **Klasör:** Çalışılan alt proje klasörü (`backend/`, `ios/`…). Birden fazlaysa
    virgülle ayır (`backend/, frontend/`). Repo geneli bir işse `/`.
  - **Özet:** Bir cümle, ne değişti (nasıl değil).
  - **Günlük linki:** O iş için `gunluk/` kaydı varsa sona eklenir, yoksa yazılmaz.
- Daily done satırları **CLAUDE.md'ye yazılmaz**: CLAUDE.md her oturumda baştan sona yüklenir,
  büyüyen bir kayıt her oturumda boşuna bağlam harcar.

## Dosya adları

- Günlük ve hata kayıtları: `YYYY-MM-DD-kisa-slug.md`
- Daily done: `YYYY-MM.md`
- Diğerleri: `konu-slug.md`
- Türkçe karakter ve boşluk yok.

## Linkler (GitHub + Obsidian uyumu)

- Wiki içi linkler **standart markdown linki**, göreli yol ve `.md` uzantısıyla yazılır:
  `[holdings servisi](../servisler/holdings-service.md)`.
- `[[wikilink]]` ve `![[gömme]]` kullanılmaz: GitHub'da çalışmaz ve Claude'un dosyayı
  bulmasını zorlaştırır. (Vault'un kendi `ana-sayfa.md`'si repo dışında olduğu için istisnadır.)
- Kod dosyalarına link repo köküne göre değil wiki dosyasına göre göreli yazılır
  (`../../backend/portfolio/services/holdings.py`); frontmatter'daki `related` alanında ise
  repo köküne göre yol yazılır.
- Görseller `wiki/_ekler/` altında durur, standart markdown ile gömülür: `![açıklama](../_ekler/x.png)`.

## Frontmatter

Her wiki dosyası şu YAML başlığıyla başlar. Obsidian bunu "Properties" olarak gösterir;
`tags` Obsidian etiket aramasına ve grafiğe girer.

```yaml
---
title: Kısa başlık
date: YYYY-MM-DD
phase: faz-X
type: gunluk            # gunluk | hata | referans | roadmap | script | servis | daily-done
tags: []                # boşluksuz, küçük harf; çok kelimeliyse tire: [guvenlik, api-sozlesmesi]
related: []             # ilgili kod dosyaları / diğer wiki sayfaları (repo köküne göre yol)
status: guncel          # gunluk: kapandi | hata: acik/cozuldu | dok: guncel/arsiv
---
```

## Kurallar

- Günlükte "Alınan kararlar" bölümü her kararın **gerekçesini ve elenen alternatifi** içerir.
- Günlüğün "Sonraki adım" bölümü bir sonraki oturumun ilk işidir; bağlamı geri yüklemenin en hızlı yolu.
- Servis dokümanı formül ve invariant'ları içermek zorundadır.
- Bir wiki indeksi üretiliyorsa (vira: `wiki/scripts/gen_index.py`) günlük eklendikten sonra
  indeks yeniden üretilir.
- Obsidian'da elle yazılan notlar da bu kurallara uyar; Obsidian'ın oluşturduğu
  `Untitled.md` gibi boş dosyalar commit'lenmez.
