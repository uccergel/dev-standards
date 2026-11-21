# Ana Sayfa

Tüm projelerin wiki'leri bu vault'ta. Her klasör bir reponun `wiki/` klasörüne bağlı;
burada yazılan not doğrudan o repoya düşer, git ile commit'lenir.

Bu sayfa repo dışındadır (vault kökünde), bu yüzden burada `[[wikilink]]` serbest.
Projelerin içindeki notlarda standart markdown linki kullan (bkz. [[standards/standards/wiki|wiki kuralları]]).

> Aşağıdaki tablolar **Dataview** eklentisiyle çalışır
> (Settings → Community plugins → Browse → "Dataview" → Install + Enable).
> Eklenti yoksa kod blokları düz metin olarak görünür.

## Daily done (son 40)

```dataview
TABLE WITHOUT ID
  split(file.folder, "/")[0] AS Proje,
  meta(L.section).subpath AS Gün,
  L.text AS İş
FROM ""
WHERE type = "daily-done" AND !contains(file.name, "_template")
FLATTEN file.lists AS L
SORT meta(L.section).subpath DESC, L.text DESC
LIMIT 40
```

## Açık yol haritası maddeleri

Her projenin `wiki/roadmaps/` dosyalarındaki işaretlenmemiş `- [ ]` maddeleri, projeye
göre gruplu. Şablonlar (`_template`) ve `status: arsiv` olan planlar listelenmez.
Kutuyu burada işaretlersen değişiklik doğrudan ilgili roadmap dosyasına yazılır.

```dataview
TASK
FROM ""
WHERE !completed
  AND contains(file.folder, "roadmaps")
  AND !contains(file.name, "_template")
  AND default(file.frontmatter.status, "") != "arsiv"
GROUP BY split(file.folder, "/")[0] AS Proje
```

## Son oturum günlükleri

Klasöre göre seçer; böylece standart frontmatter'ı (`title`, `date`) ve vira'nın Türkçe
şemasını (`baslik`, `tarih`), kitabe'nin `created` alanını birlikte gösterir.

```dataview
TABLE WITHOUT ID
  link(file.path, default(title, default(baslik, file.name))) AS Günlük,
  split(file.folder, "/")[0] AS Proje,
  default(date, default(tarih, created)) AS Tarih
FROM ""
WHERE contains(file.folder, "gunluk") AND !contains(file.name, "_template") AND file.name != "README"
SORT default(date, default(tarih, created)) DESC
LIMIT 20
```

## Açık hatalar

```dataview
TABLE WITHOUT ID
  file.link AS Hata,
  split(file.folder, "/")[0] AS Proje,
  date AS Tarih
FROM ""
WHERE type = "hata" AND status = "acik" AND !contains(file.name, "_template")
SORT date DESC
```

## Standartlar

- [[standards/standards/workflow|Çalışma kuralları]]
- [[standards/standards/architecture|Mimari ve klasör yapısı]]
- [[standards/standards/security|Güvenlik kontrol listesi]]
- [[standards/standards/wiki|Wiki disiplini]]
