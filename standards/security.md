# Güvenlik kontrol listesi

Bu liste bereket (2026-10-28, G-01…G-16) ve vira (2026-10-27, Y/O/D/B) güvenlik
denetimlerinde **gerçekten bulunan** açıklardan çıkarıldı. Her madde parantez içinde
kaynağını gösterir. Yeni bir proje internete açılmadan önce bu liste baştan sona geçilir;
uyulmayan madde varsa projenin wiki'sinde gerekçesiyle yazılır.

Bir değişiklik aşağıdaki alanlardan birine dokunuyorsa (auth, ayarlar, deploy, bağımlılık,
dosya yükleme) ilgili maddeleri değişiklikten sonra yeniden kontrol et.

## Secret yönetimi
- [ ] `.env`, `.env.*` (`.env.example` hariç) ve `Local.xcconfig` `.gitignore`'da.
- [ ] Her secret için commit'lenmiş bir örnek var (`.env.example`), değer olarak yer tutucu.
- [ ] `SECRET_KEY` / `AUTH_SECRET` prod'da **zorunlu**: tanımlı değilse uygulama açılmaz,
      güvensiz varsayılana düşmez. (G-01)
- [ ] Repo geçmişinde sızmış secret varsa değiştirildi (rotate); geçmişten silmek yetmez. (B-1)
- [ ] Üçüncü parti API anahtarları (Gemini, Google Books, Raindrop…) yalnızca sunucuda okunur;
      `VITE_*` / `EXPO_PUBLIC_*` değişkenlerine **asla** secret konmaz, çünkü bunlar istemci
      paketine gömülür.

## Kimlik doğrulama
- [ ] Login, refresh ve parola uçlarında hız sınırı var (ör. login 5/dk/IP); aşılınca `429` + `Retry-After`. (G-02, Y-1)
- [ ] Hız sınırı istemci IP'sini doğru alıyor: proxy sayısı ayarlı (`NUM_PROXIES`), `X-Forwarded-For` ile atlatılamıyor. (Y-1, G-05)
- [ ] Hız sınırı sayaçları cache düşerse kapalı kalmıyor (fail-open değil) veya bu bilinçli kabul edildi. (D-5)
- [ ] Refresh token iptal edilebiliyor (blacklist); çıkış, parola değişimi ve sıfırlama mevcut oturumları düşürüyor. (G-07, Y-3)
- [ ] Kayıt (register) internete açık kurulumda varsayılan olarak **kapalı** veya davet kodlu.
- [ ] Yetki kontrolü nesne düzeyinde: bir kullanıcı başka kullanıcının kaydını ID değiştirerek okuyamıyor/değiştiremiyor. (O-1, D-2)

## Yönetim yüzeyleri
- [ ] Django admin prod'da varsayılan kapalı (`ADMIN_ENABLED=False` → `/admin/` 404); gerektiğinde geçici açılır. (G-08)
- [ ] Admin açıksa admin login'inde de hız sınırı var. (Y-2)
- [ ] API kullanıcısı superuser değil.
- [ ] OpenAPI şeması, Swagger UI ve Redoc yalnızca dev'de açık (`API_DOCS_ENABLED`). (G-04, D-1)

## HTTP ve tarayıcı
- [ ] Django proxy arkasında HTTPS'i tanıyor (`SECURE_PROXY_SSL_HEADER`); HSTS, `SECURE_SSL_REDIRECT`, secure cookie açık. (G-05)
- [ ] Web yanıtlarında güvenlik başlıkları var: CSP, `X-Frame-Options`/`frame-ancestors`, `X-Content-Type-Options`, `Referrer-Policy`. (G-06, O-2)
- [ ] Başlıklar canlıda `curl -I https://<alan-adı>` ile doğrulandı. (O-2)
- [ ] CORS yalnızca bilinen web origin'lerine açık; `*` yok.
- [ ] Sunucu sürüm bilgisi gizli (`server_tokens off`, banner yok). (B-2)

## Girdi ve dosya yükleme
- [ ] İstek gövdesi için üst sınır var (`DATA_UPLOAD_MAX_MEMORY_SIZE`); aşılırsa `413`. (G-10, D-3)
- [ ] Yüklenen dosyalarda boyut ve tür sınırı var; medya dosyaları kalıcı bir volume'da. (D-3)
- [ ] Geçersiz sorgu parametresi `400` döner, `500` değil. (D-4)
- [ ] Harici servisten (LLM, fiyat feed'i, OCR) gelen veri doğrulanmadan DB'ye yazılmaz; LLM çıktısı kullanıcı onayından geçer. (G-15)
- [ ] Hata yanıtlarında stack trace, SQL veya harici servisin ham hata metni sızmıyor. (G-10)

## Bağımlılıklar ve tedarik zinciri
- [ ] Python bağımlılıkları sabit sürümle (`==`), npm lockfile commit'li. `"latest"` sürüm aralığı yok. (G-11)
- [ ] Docker imajları ve CDN script'leri sabit sürümle; `:latest` / `@latest` yok. (G-04, O-3, G-11)
- [ ] Bilinen açık taraması düzenli yapılıyor: `npm audit`, `pip-audit` (veya OSV). CI'da çalışıyor. (G-03, Y-4, O-4, O-5)
- [ ] Kullanılmayan bağımlılık temizlendi. (B-3)
- [ ] `docker.sock`'a erişen konteyner yok; varsa gerekçesi yazılı. (O-3)

## Loglama ve kurtarma
- [ ] Güvenlik olayları ayrı bir logger'a yazılıyor: başarısız login, throttle (`429`), yetki reddi. (G-09)
- [ ] Veritabanı yedeği otomatik alınıyor ve **geri yükleme en az bir kez denendi**. (G-12)

## Mobil ve iOS
- [ ] Token'lar Keychain / SecureStore'da; erişim sınıfı `AfterFirstUnlockThisDeviceOnly` gibi cihaza bağlı. (G-13)
- [ ] Uygulama arka plana geçince hassas ekran gizleniyor (privacy cover). (G-13)
- [ ] Yeniden kurulumda eski Keychain oturumu temizleniyor. (G-13)
- [ ] `DEVELOPMENT_TEAM` ve imza bilgileri `Local.xcconfig`'te, repoda değil. (G-16)

## Veri bütünlüğü
- [ ] Birden fazla satır yazan işlemler `transaction.atomic` içinde. (G-14)
- [ ] Yarış durumuna açık iş kuralları (ör. stoktan fazla satış) DB kilidi veya constraint ile korunuyor, yalnızca serializer kontrolüyle değil. (G-14)
- [ ] Finansal veya geçmiş verisi PROTECT FK ile korunuyor; kazara silinemiyor.

## Regresyon testleri

Düzeltilen her güvenlik açığı için bir test yazılır (bereket: `common/tests/test_security.py`,
vira: `core/tests/test_security_regressions.py`). Ayar tabanlı korumalar (admin kapalı,
docs kapalı, HSTS açık) da testle sabitlenir; böylece bir ayar değişikliği korumayı sessizce kaldıramaz.
