# Obsidian kurulumu

Tüm projelerin wiki'leri tek bir Obsidian vault'unda toplanır. Vault **repoların dışında**
durur ve her reponun `wiki/` klasörüne bağlantı (macOS'ta symlink, Windows'ta junction)
verir. Böylece:

- Obsidian'da yazdığın not doğrudan ilgili reponun `wiki/` klasörüne düşer, git ile commit'lenir.
- Claude bulut oturumlarında aynı dosyaları repodan okur ve yazar.
- Obsidian'ın `.obsidian/` ayar klasörü hiçbir repoya girmez.

```
~/Obsidian/dev/            ← Obsidian'da açılan vault
├── .obsidian/             ← Obsidian ayarları (git dışı)
├── ana-sayfa.md           ← tüm projelerin daily done'ı, son günlükler, açık hatalar
├── standards  → ~/kod/dev-standards
├── bereket    → ~/kod/bereket/wiki
├── vira       → ~/kod/vira/wiki
└── …
```

## 1. Vault'u kur

Repoların hepsi aynı klasörün altında olmalı (ör. `~/kod/bereket`, `~/kod/vira`,
`~/kod/dev-standards`). İlk argüman bu klasör, ikincisi (isteğe bağlı) vault'un yeri.

**macOS:**

```bash
bash ~/kod/dev-standards/obsidian/setup-vault.sh ~/kod
```

**Windows (CMD):**

```bat
C:\kod\dev-standards\obsidian\setup-vault.cmd C:\kod
```

Script'i tekrar çalıştırmak güvenlidir: var olan bağlantılara ve dosyalara dokunmaz.
Yeni bir repo klonladığında yeniden çalıştırman yeterli. Henüz `wiki/` klasörü olmayan
repolar atlanır.

## 2. Obsidian'da aç

Obsidian → **Open folder as vault** → `~/Obsidian/dev` (Windows: `%USERPROFILE%\Obsidian\dev`).

## 3. Ayarları kontrol et

Script şu ayarları yazar (vault ilk kez kuruluyorsa). Obsidian'da doğru göründüklerini kontrol et:

| Ayar | Değer | Neden |
|------|-------|-------|
| Files and links → Use [[Wikilinks]] | **Kapalı** | Notlar GitHub'da da çalışsın |
| Files and links → New link format | **Relative path to file** | Linkler repoda taşınabilir kalsın |
| Files and links → Automatically update internal links | **Açık** | Dosya taşınınca linkler kırılmasın |
| Core plugins → Templates → Template folder location | `standards/templates/wiki` | Wiki şablonları |

Elle açman gerekenler:

- **Core plugins → Templates:** Aç. Yeni bir günlük açarken komut paletinden
  "Templates: Insert template" ile `gunluk/_template` seçilir; tarih otomatik dolar.
- **Community plugins → Dataview:** Kur ve aç. `ana-sayfa.md`'deki tablolar bununla çalışır.

## Git ile çalışırken

- Obsidian dosyaları değiştirir ama commit'lemez. Her repoda değişiklikleri her zamanki gibi
  commit'le. İstersen "Obsidian Git" eklentisi bunu otomatikleştirebilir; kurmadan önce hangi
  repolara commit atacağını iyi ayarla.
- Bir repoyu doğrudan Obsidian'da vault olarak **açma**: repoya `.obsidian/` klasörü düşer.
  Açtıysan `.obsidian/` klasörünü o reponun `.gitignore`'una ekle.
- Obsidian'ın oluşturduğu boş `Untitled.md` dosyalarını commit'leme.
- `standards/` altındaki dosyaları Obsidian'dan düzenlersen değişiklik `dev-standards`
  reposuna düşer; projelerdeki `docs/standards/` submodule'ü ancak
  `git submodule update --remote docs/standards` ile güncellenir.
