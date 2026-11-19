---
name: standartlara-bagla
description: Kodu olan mevcut bir repoyu uccergel/dev-standards'a bağlar — docs/standards submodule'ü, standartları import eden CLAUDE.md, izinler, wiki/daily-done; tekrar eden kuralları temizler, sapmaları gerekçesiyle yazar, eskimiş belgeleri ve kodda fark edilen hataları raporlar. Kullanıcı bir projeyi "standartlara bağla", "dev-standards'a bağla", "CLAUDE.md'yi standartlaştır" dediğinde kullan. Boş/yeni repo için değil — onun için yeni-proje.
---

# Mevcut projeyi standartlara bağlama

Amaç: proje kurallarını **koruyarak** ortak standarda bağlamak. Proje kuralı standarttan
önce gelir; çelişen her şey "Standarttan sapmalar" bölümüne gerekçesiyle yazılır,
zorla değiştirilmez. Kod davranışını bu işte değiştirme — bulduğun hataları raporla.

## 1. Oku (değiştirmeden)

- Var olan AI kuralları: `CLAUDE.md` (kök + alt klasörler), `AGENTS.md`, `.cursorrules`,
  `.claude/settings.json` (içindeki anahtarlar **korunacak**).
- Proje kendi standartlarını yazmış mı: `wiki/referans/*standart*`, `CONTRIBUTING.md`.
  Commit dili/biçimi, kod yorumu dili, adlandırma kuralları buradan gelir.
- Wiki: var mı, frontmatter şeması ne, indeks üreten script ve onu denetleyen CI var mı?
  Varsa **şemayı değiştirme**; sapma olarak yaz.
- Klasör adları, varsayılan dal, CI iş akışları, git hook'ları (ör. sürüm artıran
  post-commit), deploy dosyaları (Dockerfile, compose), `.gitignore`'da secret'lar.
- Git geçmişinden büyük yapısal değişiklikler (`git log --diff-filter=D --stat`):
  silinmiş klasörleri anlatan belgeler eskimiş olabilir.

## 2. Bugünkü durumu ölç

Projenin kendi kontrol komutlarını (lint, tip, test, build) **değişiklikten önce**
çalıştır ve sonucu not et — bağladıktan sonra "yeni hata yok" diyebilmek için.

Bilinen tuzaklar:
- `npm ci` lock dosyası uyumsuz derse: Dockerfile'da sabitlenmiş npm sürümüne bak ve
  `npx -y npm@<o sürüm> ci` kullan; lock dosyasını değiştirme.
- Prisma `postinstall` veritabanı adresi isterse, `.env.example`'daki yerel adresi
  ortam değişkeni olarak ver (bağlanmaz, yalnızca okur); `.env` dosyası oluşturma.
- TanStack Router tip hataları (`'"/x"' not assignable to 'undefined'`): önce build
  (route ağacını üretir), sonra tip kontrolü.

## 3. Karşılaştır

Standart dosyaları: `https://github.com/uccergel/dev-standards` → `standards/*.md`
(submodule eklendikten sonra `docs/standards/standards/`). Çıkar:

- **Tekrar edenler:** proje CLAUDE.md'sinde standartla aynı olan maddeler → silinecek.
  Projeye özel ayrıntısı olan madde silinmez, "projeye özel ekler"e taşınır.
- **Sapmalar:** klasör adları, stack farkı (Django değilse karşılıkları), commit/yorum
  dili, wiki şeması, varsayılan dal, iOS proje yönetimi.
- **Eskimiş belgeler:** artık var olmayan klasör/uç/sayfayı anlatanlar.
- **Fark edilen hatalar ve güvenlik açıkları:** düzeltme, listele (gerekirse
  `guvenlik-taramasi` öner).

## 4. Plan ve onay

Değişecek dosyaları, kaldırılacak/taşınacak maddeleri ve sapmaları listele; **onay bekle**.

## 5. Uygula

Konu dalında (`chore/dev-standards`):

1. `git submodule add https://github.com/uccergel/dev-standards docs/standards`
2. Kök `CLAUDE.md`'nin başına `@docs/standards/CLAUDE.md` ve kısa açıklama; tekrar edenleri
   sil, "Standarttan sapmalar" ve "… projeye özel ekler" bölümlerini yaz. CLAUDE.md yoksa
   `docs/standards/templates/project/CLAUDE.md`'den yaz; domain eşleme tablosunu koddan
   çıkar (route, app, istemci klasörü).
3. `.claude/settings.json`: `docs/standards/claude/settings.json`'daki `permissions`,
   `extraKnownMarketplaces` ve `enabledPlugins` anahtarlarını **birleştir**; var olan
   anahtarları silme.
4. `wiki/daily-done/YYYY-MM.md` ve (yoksa) `wiki/gunluk/`; projenin wiki şemasına uy.
   İndeks script'i varsa çalıştır, CI denetimi varsa (`--check`) geçtiğini gör.
5. Prettier/ESLint `.` tarıyorsa `docs/standards/`'ı ignore et; yeni dosyaları biçimle.
6. Git hook'u gerektiren proje kuralı varsa (ör. sürüm artıran hook) etkinleştir.
7. Mimari belgede klasör ağacı varsa `docs/standards/` ve `.claude/settings.json`'ı ekle.
8. Günlük + daily done yaz. Commit mesajı **projenin** kuralına göre (yoksa Conventional
   Commits). Push'la, PR bağlantısını ver.

## 6. Doğrula ve raporla

- Import zincirinin yüklendiğini gör (CLAUDE.md değişince standart dosyaları bağlama gelir).
- 2. adımdaki kontrolleri tekrar çalıştır: yeni hata yok.
- Rapor: yapılanlar, sapmalar + gerekçe, senin adına verdiğin kararlar, ölçülen durum,
  **düzeltilmeyen** bulgular (önem sırasıyla), sonraki adım önerisi.
