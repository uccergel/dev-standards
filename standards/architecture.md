# Mimari ve klasör yapısı

## Klasör adları (yeni projeler için)

Birden fazla parçası olan her uygulama tek repoda (monorepo) durur ve şu adları kullanır:

```
<proje>/
├── backend/            # API sunucusu (Django + DRF varsayılan)
├── web/                # Web istemcisi
├── mobile/             # Çapraz platform mobil istemci (Expo / React Native)
├── ios/                # Native iOS istemcisi (Swift + SwiftUI)
├── android/            # Native Android istemcisi (Kotlin + Jetpack Compose)
├── packages/
│   └── shared/         # TS istemcilerin ortak kodu: API tipleri, zod şemaları, queryKeys, api-core
├── deploy/             # Dockerfile'lar, reverse proxy (Caddy/nginx) ayarları, yedekleme script'leri
├── wiki/               # Projenin yaşayan hafızası (bkz. wiki.md)
├── docs/standards/     # bu repo (git submodule)
├── .claude/settings.json
├── .env.example
├── docker-compose.yml
├── package.json        # npm workspaces: web, mobile, packages/*
├── CLAUDE.md
└── README.md
```

- Olmayan parça için klasör açılmaz (ör. yalnızca web olan bir projede `mobile/` yok,
  native Android istemcisi yazılmadıkça `android/` yok).
- **Mobil adlandırma kuralı:** klasör adı istemcinin *hangi platform için, hangi dille*
  yazıldığını söyler.
  - `mobile/`: tek kod tabanı, birden fazla platform (Expo/React Native; ileride Flutter
    olursa o da). Expo'nun `prebuild` ile ürettiği `mobile/ios/` ve `mobile/android/`
    klasörleri bu klasörün **içinde** kalır ve gitignore'ludur (Continuous Native Generation);
    kök `ios/` ve `android/` ile karışmaz.
  - `ios/`: yalnızca Swift ile yazılmış native iOS uygulaması.
  - `android/`: yalnızca Kotlin ile yazılmış native Android uygulaması.
  - Aynı projede `mobile/` ile `ios/` yan yana durabilir (bereket örneği: Expo ve native iOS
    birlikte). Bu durumda hangisinin asıl istemci olduğu projenin wiki'sinde yazılır.
- Klasör adları İngilizce ve küçük harf; Türkçe karakter ve boşluk yok.
- Her alt projenin kendi `CLAUDE.md`'si olur: yalnızca o klasöre özgü yapı, kural, komut ve
  "Bitirmeden önce" listesi. Repo geneli kurallar kök `CLAUDE.md`'de kalır.
- Paket yöneticisi: **npm workspaces**. Lockfile (`package-lock.json`) commit'lenir.

**Mevcut projeler** (standarttan önce kuruldu, yeniden adlandırılmaz): bereket `frontend/`,
vira `client/` + `api/api/` + `ios-app/`, kitabe `client/` + `mobil/`. Sapma her projenin
kendi `CLAUDE.md`'sinde yazılıdır.

## Tek tek uygulamalar (monorepo olmayan)

Tek parçalı uygulamalar (ör. yalnızca bir web sitesi veya yalnızca bir iOS oyunu) kökte
doğrudan kendi framework'ünün varsayılan yapısını kullanır; `web/` gibi bir alt klasöre
sarılmaz. `wiki/`, `CLAUDE.md`, `.claude/settings.json` ve `docs/standards/` yine olur.

## Katman kuralları

1. **İş mantığı backend'de.** Hesaplar (toplam, oran, getiri, istatistik) backend servis
   katmanında yapılır; istemciler hazır sonucu gösterir. Aynı formülün iki istemcide ayrı
   ayrı yazılması yasak.
2. **Backend katmanları:** `models` (veri + constraint) → `services/` (iş mantığı, ORM
   burada konuşur) → `api/serializers` (doğrulama + şekil) → `api/views` (ince HTTP katmanı).
   View ve serializer içinde hesap yapılmaz.
3. **Domain sınırları test ile korunur**, konvansiyonla değil (bereket: `test_boundaries.py`,
   vira: `import-linter`). Birbirini tanımaması gereken app'ler varsa kural bir testte yazılır.
4. **Server state yalnızca TanStack Query cache'inde.** Zustand (veya benzeri) yalnızca UI
   state tutar: tema, açık dialog, seçili görünüm. Server verisi kopyalanmaz.
5. **Feature bazlı düzen.** İstemcilerde kod `features/<domain>/` altında yan yana durur;
   global `hooks/`, `components/` klasörleri yalnızca gerçekten ortak parçalar içindir.
   shadcn bileşenleri `components/ui/` altındadır ve elle düzenlenmez (CLI ile eklenir).
6. **Para ve hassas sayılar:** parasal değerlerde float/`Double` yok. DB'de `NUMERIC`,
   Python'da `Decimal`, API'de string, Swift'te `Decimal(string:)`.

## API sözleşmesi

- Prefix ve sürüm: `/api/v1/`. Kırıcı değişiklik gerekirse `/api/v2/` açılır, v1 yaşar.
- Doğruluk kaynağı backend serializer'larıdır; OpenAPI şeması `drf-spectacular` ile üretilir
  ve **yalnızca dev'de** açıktır (bkz. `security.md`).
- Tarihler ISO 8601, Decimal alanlar string.
- Hata formatı tek tiptir (DRF standardı veya projenin hata zarfı) ve tüm istemciler aynı
  hata işleyiciyi kullanır.
- Liste uçlarında sayfalama vardır; sınırsız liste dönen uç açılmaz.
- Silme korumalı kayıtlar (PROTECT FK) `409 Conflict` döner, ham `500` değil.
- `GET /api/v1/healthz/`: kimliksiz, DB'ye dokunmayan canlılık ucu.

### Domain eşleme tablosu (zorunlu)

Birden fazla istemcisi olan her projenin kök `CLAUDE.md`'sinde bir **domain eşleme tablosu**
bulunur: her domain için backend app, API yolu ve her istemcideki klasör. Bir serializer
alanı eklendiğinde, silindiğinde veya yeniden adlandırıldığında tablodaki **tüm istemcilerin
tipleri** güncellenir; güncellenmeyen istemci kalırsa açıkça raporlanır.

İstemci tipleri şemadan üretilmiyorsa elle yazılan tek kaynak `packages/shared/src/types/api.ts`
dosyasıdır; Swift modelleri onu izler, çelişkide `api.ts` doğrudur.

## Auth (varsayılan)

- SimpleJWT: kısa ömürlü access (≈30 dk) + uzun ömürlü, rotate edilen refresh (≈30 gün).
- Refresh blacklist açık (`BLACKLIST_AFTER_ROTATION=True`); çıkışta istemci refresh'i
  `auth/token/blacklist/` ucuna gönderir ve istek başarısız olsa bile yerel token'ı siler.
- Parola değişikliğinde kullanıcının tüm refresh token'ları iptal edilir.
- Token saklama: web `localStorage` (CSP ile birlikte), Expo `expo-secure-store`, iOS Keychain.

## iOS

- Swift + SwiftUI, deployment target projede belirtilir.
- **Varsayılan proje yönetimi: Xcode "file system synchronized root group"** (objectVersion 77).
  Dosya listesi `project.pbxproj`'de tutulmaz, merge conflict çıkmaz, ek araç gerekmez.
- Uygulama birden fazla yerel SPM paketine bölünecek kadar büyürse **XcodeGen** kullanılabilir
  (vira örneği); bu karar projenin wiki'sine gerekçesiyle yazılır.
- Ortam ayarları `Config/*.xcconfig` katmanında: `Shared`, `Debug`, `Release` commit'lenir;
  `Local.xcconfig` (`DEVELOPMENT_TEAM` vb.) gitignore'ludur, örneği `Local.xcconfig.example`.
- `API_BASE_URL` gibi değerler xcconfig → `Info.plist` → `Config.swift` zinciriyle okunur;
  kodda sabit URL yok.
- Testler Swift Testing ile; derleme doğrulaması imzasız yapılabilir:
  `xcodebuild -scheme <App> -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`.

## Deploy (varsayılan)

- Docker Compose + reverse proxy (Caddy veya Dokploy/Traefik), tek origin: web statik dosyaları
  ve `/api/` aynı alan adından servis edilir (CORS ve cookie derdi yok).
- Docker imajları ve CDN script'leri sabit sürümle (`:latest` / `@latest` yok).
- Konteynerin healthcheck'i `/api/v1/healthz/`'ye bakar.
