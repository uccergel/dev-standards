---
name: yeni-proje
description: Yeni bir uygulama reposunu uccergel/dev-standards yapısıyla sıfırdan kurar — klasörler, docs/standards submodule'ü, CLAUDE.md, Claude izinleri, .gitignore, .env.example ve wiki iskeleti. Kullanıcı yeni bir proje, uygulama, servis ya da repo başlatmak istediğinde ("yeni proje", "yeni uygulama kur", "/yeni-proje") kullan. Var olan ve kodu olan bir repoyu standartlara bağlamak için değil — onun için standartlara-bagla.
---

# Yeni proje kurulumu

Kurallar `uccergel/dev-standards` reposundadır. Bu skill o kuralları **kopyalamaz**,
projeye submodule olarak bağlar ve projeye özel kısmı doldurur. Kuralların kendisini
(klasör adları, katmanlar, güvenlik, wiki) kurulumun 3. adımından sonra
`docs/standards/` altından oku; bu dosyadaki özetle çelişirse orası doğrudur.

## 1. Durumu anla

- Çalışma klasörü boş bir git reposu mu, uzak (`origin`) tanımlı mı, varsayılan dal ne?
  Repo yoksa kullanıcıya GitHub'da boş repo açmasını ve bu oturuma bağlamasını söyle;
  kendin repo oluşturamazsın.
- Klasörde kod varsa dur: bu iş `standartlara-bagla` skill'inin işidir.

## 2. Kullanıcıya sor (AskUserQuestion)

Tek seferde, en fazla 4 soru. Cevabı açık olanı sorma.

1. **Uygulama ne yapacak?** (bir-iki cümle; CLAUDE.md'nin ilk paragrafı olur)
2. **Hangi parçalar?** (çoklu seçim) — backend (Django + DRF varsayılan), web, mobil
   (Expo), native iOS, native Android. Tek parça + backend yoksa "tek parçalı uygulama"
   kuralı geçerli: kökte, framework'ün varsayılan düzeniyle.
3. **Web için:** Vite SPA + Django API mı, yoksa TanStack Start (web + API tek
   uygulama, Prisma) mı? Kararın gerekçesini kısa ver: ayrı backend gereksizse tek
   uygulama daha az altyapıdır (kitabe/Lectio örneği); birden çok istemci (web + iOS +
   Expo) aynı API'yi kullanacaksa Django (bereket/vira örneği).
4. **Dağıtım ve kimlik:** Dokploy'da bir alan adı mı? Kullanıcı girişi olacak mı?

## 3. Plan ve onay

Çalışma kuralı 1 gereği: oluşturacağın klasör ve dosyaları, seçilen stack'i ve
gerekçesini listele, **onay bekle**. Yalnızca seçilen parçaların klasörleri açılır
(`backend/`, `web/`, `mobile/`, `ios/`, `android/`, `packages/shared/` yalnızca iki TS
istemcisi varsa).

## 4. İskelet

Onaydan sonra, konu dalında (`chore/iskelet`):

1. `git submodule add https://github.com/uccergel/dev-standards docs/standards`
   — artık kuralları `docs/standards/standards/*.md`'den oku.
2. `.claude/settings.json` ← `docs/standards/claude/settings.json` (izinler + bu plugin'in
   marketplace kaydı).
3. `.gitignore`: en az `node_modules/`, `.env`, `.env.*`, `!.env.example`, build çıktıları,
   `.venv/`, `__pycache__/`, `.DS_Store`, `.idea/`, `.obsidian/`, iOS varsa
   `**/Config/Local.xcconfig`.
4. `.env.example`: her secret için yer tutucu ve bir satır açıklama.
5. Seçilen parçaların iskeleti — **resmî üreticilerle** (ör. `npm create vite@<sürüm>`,
   `django-admin startproject config backend`, `npx create-expo-app@<sürüm>`). Komutlarda
   ve `package.json`'da `latest` yazma; o günkü sürümü sabitle (`security.md` →
   Bağımlılıklar). Lockfile'ı commit'le.
6. Backend varsa güvenlik listesinin "ilk günden" maddelerini iskelete koy:
   `SECRET_KEY`/`AUTH_SECRET` zorunlu (yoksa açılmasın), kayıt varsayılan kapalı, admin ve
   API dokümanları yalnızca dev'de, kimlik uçlarında hız sınırı (IP'yi
   `X-Forwarded-For`'un **sağ** tarafından al — h3/Express'in "ilk girdi" yardımcılarını
   kullanma), `GET /api/v1/healthz/`.
7. `CLAUDE.md` ← `docs/standards/templates/project/CLAUDE.md`. Projeye göre doldur:
   stack, "Standarttan sapmalar" (yoksa bölümü sil), birden çok istemci varsa domain
   eşleme tablosu, komutlar, "Bitirmeden önce" listesi. Uydurma komut yazma; yalnızca
   iskelette gerçekten çalışanları yaz.
8. Wiki: `wiki/README.md`, `wiki/gunluk/_template.md`, `wiki/daily-done/_template.md`
   (`docs/standards/templates/wiki/`'den kopya). Diğer klasörler ihtiyaç olunca açılır.
9. Prettier/ESLint kullanılıyorsa `docs/standards/` ve `wiki/**/_template.md`'yi ignore
   dosyalarına ekle — yoksa submodule biçim kontrolünü kirletir.

## 5. Doğrula ve kaydet

- İskeletin build/lint/test komutlarını çalıştır; sonuçları olduğu gibi raporla.
- İlk günlüğü (`wiki/gunluk/YYYY-MM-DD-proje-kurulumu.md`) ve daily done satırını yaz
  (`daily-done` skill'i).
- Conventional Commits ile commit'le, dalı push'la, PR bağlantısını ver. Doğrudan
  varsayılan dala push'lama.

## Raporla

Kurulan klasörler, seçilen stack + gerekçe, çalıştırılan kontroller ve sonuçları,
kullanıcının yapması gerekenler (Dokploy'da uygulama + alan adı, DNS kaydı, secret'lar).
