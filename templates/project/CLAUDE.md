# <Proje adı>

<Tek cümle: uygulama ne yapar, kimin için.>

@docs/standards/CLAUDE.md

Yukarıdaki ortak standartlar bu projede de geçerlidir. Bu dosya yalnızca projeye özel
kuralları ve standarttan sapmaları tutar. Alt projelerin kendi `CLAUDE.md` dosyaları
vardır ve o klasörde çalışırken ek olarak okunur: `backend/CLAUDE.md`, `web/CLAUDE.md`, …

## Stack
- Backend: <…> (`backend/`)
- Web: <…> (`web/`)
- Mobil: <…> (`mobile/`)
- iOS: <…> (`ios/`)

## Standarttan sapmalar
<Yoksa bu bölümü sil. Varsa her sapma + gerekçesi. Ör.:>
- Web klasörü `client/`: standarttan önce kuruldu, yeniden adlandırılmadı.

## Tasarım kaynakları (gerektiğinde oku)
- Şema: @wiki/referans/01-database-design.md
- Mimari + API sözleşmesi: @wiki/referans/02-architecture.md

## Domain eşleme tablosu

| Domain | Backend app | API yolu | Web (`web/src/features/`) | Mobil | iOS |
|--------|-------------|----------|---------------------------|-------|-----|
| Kimlik | `common` | `auth/…` | `auth` | `login.tsx` | `Auth` |

## Değişmez kurallar (projeye özel)
- <Domain'e özgü kurallar: formüller, birimler, sınırlar, cache invalidation zincirleri…>

## Komutlar
- Backend test: `cd backend && python manage.py test`
- Web: `npm run dev -w web` / `npm run build -w web` / `npm run typecheck -w web`
- Mobil: `npm run start -w mobile`
- iOS (imzasız derleme): `cd ios && xcodebuild -scheme <App> -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`

## Yapma
- <Projeye özgü yasaklar.>
