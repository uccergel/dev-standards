# Çalışma kuralları

## İletişim
- Benimle Türkçe konuş; kod, değişken adları, commit mesajlarındaki teknik terimler İngilizce.
- Kritik kararlarda kısa gerekçe ver (neden bu, alternatif neydi). Bariz konularda anlatma.

## Kurallar

1. **Büyük işlerde önce plan.** Üç veya daha fazla dosyaya dokunan, model/migration ekleyen
   ya da API sözleşmesini (serializer alanı, endpoint, response şekli) değiştiren işlerde önce
   hangi dosyaları neden değiştireceğini listele ve onay bekle. Küçük ve kapsamı açık işleri
   doğrudan yap.
2. **Yalnızca repodaki koddan çalış.** Görmediğin dosya, model, endpoint veya alan uydurma.
   Emin değilsen önce dosyayı oku; yoksa sor.
3. **Küçük diff.** Bir görev, bir konu. İstenmeyen refactor, yeniden adlandırma veya biçim
   değişikliği yapma. Formatter'ı (`ruff format`, `prettier`) projede uygulanmadıysa toplu çalıştırma.
4. **Yeni bağımlılık ekleme.** Gerekiyorsa gerekçesiyle öner ve onay iste. Eklenen her
   bağımlılık sabit sürümle girer (bkz. `security.md` → Bağımlılıklar).
5. **Secret'lar repoya girmez.** Ayrıntı: `security.md` → Secret yönetimi.
6. **Varsayımları yaz.** Belirsiz bir noktada varsayım yaptıysan yanıtın sonunda
   "Varsayımlar" başlığıyla listele. Varsayım yoksa bu bölümü ekleme.
7. **Geri alınamaz işlemlerde dur.** Şema değişikliği, veri migrasyonu, API sözleşmesini bozan
   değişiklik, production verisine dokunan komut, force push: önce sor, onay al, wiki'ye
   işle, sonra uygula.
8. **Terminal komutları.** Komutları kopyalanabilir kod bloklarında ver; birbirinden bağımsız
   çalıştırılacak komutları ayrı bloklara yaz. Kabuğa özgü kısımlar (ortam değişkeni,
   zincirleme) varsa macOS/Linux (`bash`) ve Windows CMD için ayrı bloklar yaz; PowerShell
   kullanma. iOS komutları yalnızca macOS'ta çalışır.

## "Bitti" tanımı

Bir iş ancak şunlar sağlandığında bitmiştir:

- [ ] İstenen davranış çalışıyor
- [ ] Değişen davranışın testi var ve geçiyor (backend'de zorunlu; istemcide mantık içeren kodda beklenir)
- [ ] Dokunulan alt projenin lint, tip kontrolü ve test komutları temiz (alt `CLAUDE.md`'lerin "Bitirmeden önce" listesi)
- [ ] API sözleşmesi değiştiyse domain eşleme tablosundaki tüm istemciler güncellendi veya güncellenmeyenler açıkça raporlandı
- [ ] Kod ile wiki çelişmiyor; oturum günlüğü yazıldı (bkz. `wiki.md`)

Bir adım atlandıysa (ör. iOS testleri bu ortamda çalıştırılamadı) bunu açıkça söyle;
"çalışıyor olmalı" deme.

## Git

- Commit mesajı: Conventional Commits — `type(scope): özet`
  (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`).
  Özet Türkçe olabilir; `type` ve `scope` İngilizce.
- Bir commit, bir konu. Biçim değişiklikleri ayrı commit'te (`style:`).
- Doğrudan varsayılan dala değil, konu dalına çalış (`feat/...`, `fix/...`); birleştirme PR ile.
- Force push yalnızca kendi konu dalında ve `--force-with-lease` ile; varsayılan dalda asla.
- Commit'lemeden önce `git status`'a bak: `.env`, `Local.xcconfig`, build çıktısı, `node_modules` girmemeli.
