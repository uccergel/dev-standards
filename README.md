# dev-standards

Tüm uygulamalarım (bereket, vira, kitabe, website, ish, …) için ortak geliştirme
standartları: klasör yapısı, çalışma kuralları, güvenlik kontrol listesi ve wiki
disiplini. Claude Code bu dosyaları projelerin `CLAUDE.md`'si üzerinden okur.

Bu kurallar bereket ve vira'da zaten ayrı ayrı uygulanan ve oturmuş kuralların
ortaklaştırılmış hâlidir. Yeni bir kural önce bir projede denenir, işe yararsa buraya taşınır.

## İçerik

| Dosya | Ne anlatır |
|-------|------------|
| [`CLAUDE.md`](CLAUDE.md) | Giriş noktası; aşağıdaki standartları import eder |
| [`standards/workflow.md`](standards/workflow.md) | Çalışma kuralları, iletişim, "bitti" tanımı, git |
| [`standards/architecture.md`](standards/architecture.md) | Klasör adları, katman kuralları, API sözleşmesi, iOS |
| [`standards/security.md`](standards/security.md) | Güvenlik kontrol listesi (bereket + vira denetimlerinden) |
| [`standards/wiki.md`](standards/wiki.md) | Wiki klasörleri, frontmatter, ne zaman ne yazılır |
| [`claude/settings.json`](claude/settings.json) | Projelere kopyalanacak Claude izin ayarları |
| [`templates/project/CLAUDE.md`](templates/project/CLAUDE.md) | Yeni bir projenin kök `CLAUDE.md` şablonu |
| [`templates/wiki/`](templates/wiki/) | Wiki klasörleri ve `_template.md` dosyaları |

## Bir projeye bağlama

Standartlar projeye **git submodule** olarak `docs/standards/` altına eklenir. Böylece
dosyalar repo içinde durur ve hem yerelde hem bulut oturumlarında okunabilir.
(`~/.claude/CLAUDE.md` yalnızca kendi bilgisayarında çalışır, bulut oturumlarında yoktur.)

```bash
git submodule add https://github.com/uccergel/dev-standards docs/standards
```

Sonra projenin kök `CLAUDE.md`'sinin başına şunu ekle (şablon: `templates/project/CLAUDE.md`):

```markdown
@docs/standards/CLAUDE.md
```

Claude izin ayarlarını kopyala (proje kendi ihtiyacına göre genişletebilir):

```bash
mkdir -p .claude && cp docs/standards/claude/settings.json .claude/settings.json
```

### Standartları güncellemek

```bash
git submodule update --remote docs/standards
```

```bash
git commit -am "chore: dev-standards güncellendi"
```

Submodule belirli bir commit'e sabitlenir; bir projede standart değişikliğini
almak bilinçli bir adımdır, sessizce gelmez.

### Klonlarken

```bash
git clone --recurse-submodules <repo-url>
```

Daha önce klonlanmış bir repoda:

```bash
git submodule update --init
```

## Öncelik sırası

Proje kuralı ortak standarttan önce gelir. Bir proje standarttan saparsa sapma
projenin `CLAUDE.md`'sinde **gerekçesiyle** yazılır (ör. "bu projede klasör adı
`client/` — standarttan önce kuruldu, yeniden adlandırılmadı").
