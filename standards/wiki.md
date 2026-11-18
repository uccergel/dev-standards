# Wiki disiplini

Her projenin kökünde `wiki/` klasörü projenin yaşayan hafızasıdır. Claude Code dahil tüm
geliştirme oturumları onu okur ve besler. Kod ile wiki çeliştiği an wiki güncellenir:
güncel olmayan doküman, olmayan dokümandan kötüdür.

## Klasörler

| Klasör           | İçerik                                                     | Ne zaman yazılır |
|------------------|------------------------------------------------------------|------------------|
| `gunluk/`        | Oturum günlüğü: yapılan, karar + gerekçe, sonraki adım     | Her anlamlı oturumun sonunda |
| `hata-yonetimi/` | Hata kaydı: belirti → kök neden → çözüm → önlem            | Çözümü 15 dk'yı aşan her hatada; aynı hata ikinci kez yaşandıysa |
| `referans/`      | Tasarım dokümanları, API sözleşmesi, mimari kararlar, güvenlik denetimi | Tasarım değiştiğinde |
| `roadmaps/`      | Yol haritası ve faz planları (checkbox'lı)                 | Faz başında; tamamlandıkça işaretlenir |
| `scripts/`       | Script ve management command dokümanı                      | Yeni script/command eklendiğinde |
| `servisler/`     | Servis katmanı: sorumluluk, formül, invariant, test kapsamı | Yeni servis eklendiğinde / değiştiğinde |

Her klasörde kopyalanarak kullanılacak bir `_template.md` vardır (kaynak: bu reponun
`templates/wiki/`). `_template.md` dosyaları düzenlenmez.

## Dosya adları

- Günlük ve hata kayıtları: `YYYY-MM-DD-kisa-slug.md`
- Diğerleri: `konu-slug.md`
- Türkçe karakter ve boşluk yok.

## Frontmatter

Her wiki dosyası şu YAML başlığıyla başlar:

```yaml
---
title: Kısa başlık
date: YYYY-MM-DD
phase: faz-X
type: gunluk            # gunluk | hata | referans | roadmap | script | servis
tags: []
related: []             # ilgili kod dosyaları / diğer wiki sayfaları
status: guncel          # gunluk: kapandi | hata: acik/cozuldu | dok: guncel/arsiv
---
```

## Kurallar

- Günlükte "Alınan kararlar" bölümü her kararın **gerekçesini ve elenen alternatifi** içerir.
- Günlüğün "Sonraki adım" bölümü bir sonraki oturumun ilk işidir; bağlamı geri yüklemenin en hızlı yolu.
- Servis dokümanı formül ve invariant'ları içermek zorundadır.
- Bir wiki indeksi üretiliyorsa (vira: `wiki/scripts/gen_index.py`) günlük eklendikten sonra
  indeks yeniden üretilir.
