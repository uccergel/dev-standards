@echo off
rem Merkezi Obsidian vault'unu kurar (Windows CMD).
rem
rem Kullanim:  setup-vault.cmd KOD_KLASORU [VAULT_KLASORU]
rem   KOD_KLASORU   : tum repolarin durdugu klasor (ornek: C:\kod)
rem   VAULT_KLASORU : vault'un olusturulacagi yer (varsayilan: %USERPROFILE%\Obsidian\dev)
rem
rem KOD_KLASORU altindaki her repo icin:
rem   - wiki\ klasoru varsa      -> VAULT\<repo>    ->  <repo>\wiki    (junction)
rem   - repo dev-standards ise   -> VAULT\standards ->  dev-standards  (junction)
rem Junction (mklink /J) yonetici yetkisi istemez. Tekrar calistirmak guvenlidir.

setlocal enabledelayedexpansion

if "%~1"=="" (
  echo Kullanim: setup-vault.cmd KOD_KLASORU [VAULT_KLASORU]
  exit /b 1
)

set "CODE=%~f1"
if "%~2"=="" (
  set "VAULT=%USERPROFILE%\Obsidian\dev"
) else (
  set "VAULT=%~f2"
)

if not exist "%VAULT%\" mkdir "%VAULT%"

for /d %%D in ("%CODE%\*") do (
  set "NAME=%%~nxD"
  if /i "!NAME!"=="dev-standards" (
    call :link "%VAULT%\standards" "%%~fD"
  ) else if exist "%%~fD\wiki\" (
    call :link "%VAULT%\!NAME!" "%%~fD\wiki"
  )
)

if not exist "%VAULT%\.obsidian\" (
  mkdir "%VAULT%\.obsidian"
  > "%VAULT%\.obsidian\app.json" echo {"useMarkdownLinks": true, "newLinkFormat": "relative", "alwaysUpdateLinks": true}
  > "%VAULT%\.obsidian\templates.json" echo {"folder": "standards/templates/wiki"}
  echo Obsidian ayarlari yazildi: %VAULT%\.obsidian
)

if not exist "%VAULT%\ana-sayfa.md" (
  copy "%~dp0ana-sayfa.md" "%VAULT%\ana-sayfa.md" >nul
  echo Ana sayfa olusturuldu: %VAULT%\ana-sayfa.md
)

echo Vault hazir: %VAULT%
exit /b 0

:link
if exist "%~1" (
  echo Atlandi:  %~1 zaten var
  exit /b 0
)
mklink /J "%~1" "%~2" >nul
echo Baglandi: %~1 -^> %~2
exit /b 0
