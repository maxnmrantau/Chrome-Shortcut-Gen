@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

echo ============================================================
echo   AUTO SHORTCUT GOOGLE CHROME MULTI-AKUN
echo ============================================================
echo.

:: -------------------------------------------------------
:: 1. DETEKSI PATH CHROME
:: -------------------------------------------------------
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe"      set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe"       set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
    echo [ERROR] Google Chrome tidak ditemukan.
    pause & exit /b 1
)
echo [OK] Chrome : %CHROME%
echo.

:: -------------------------------------------------------
:: 2. DETEKSI FOLDER USER DATA
:: -------------------------------------------------------
set "USERDATA=%LocalAppData%\Google\Chrome\User Data"
if not exist "%USERDATA%" (
    echo [ERROR] Folder profil Chrome tidak ditemukan:
    echo         %USERDATA%
    pause & exit /b 1
)
echo [OK] User Data : %USERDATA%
echo.

:: -------------------------------------------------------
:: 3. SCAN DAN BUAT SHORTCUT UNTUK SETIAP PROFIL
:: -------------------------------------------------------
set "DESKTOP=%USERPROFILE%\Desktop"
set "BERHASIL=0"
set "VBSTEMP=%TEMP%\chrome_sc_%RANDOM%.vbs"

echo Memindai profil yang tersedia...
echo.

:: --- Profil Default ---
if exist "%USERDATA%\Default\Preferences" (
    call :BUAT_SHORTCUT "Default"
)

:: --- Profil bernama "Profile N" ---
for /L %%N in (1,1,50) do (
    if exist "%USERDATA%\Profile %%N\Preferences" (
        call :BUAT_SHORTCUT "Profile %%N"
    )
)

if exist "%VBSTEMP%" del "%VBSTEMP%" >nul 2>&1

echo.
echo ============================================================
echo   SELESAI ^| %BERHASIL% shortcut dibuat di Desktop
echo   Lokasi : %DESKTOP%
echo ============================================================
echo.
echo Catatan:
echo  - Setiap shortcut membuka profil Chrome yang terpisah.
echo  - Nama shortcut diambil dari nama akun Google di profil.
echo  - Jika ingin menambah profil baru, buka Chrome lalu klik
echo    ikon avatar kanan atas, buat profil baru, kemudian
echo    jalankan script ini lagi.
echo.
pause
endlocal
exit /b 0


:: -------------------------------------------------------
:: SUBROUTINE : Baca nama akun dari Preferences lalu buat shortcut
:: %1 = nama folder profil (contoh: Default / Profile 1)
:: -------------------------------------------------------
:BUAT_SHORTCUT
set "PROFDIR=%~1"
set "PREFFIL=%USERDATA%\%PROFDIR%\Preferences"
set "AKUNNAME="

:: Baca file Preferences (JSON) cari field "name" pertama
for /f "usebackq tokens=* delims=" %%L in ("%PREFFIL%") do (
    if not defined AKUNNAME (
        set "LINE=%%L"
        echo !LINE! | findstr /i "\"name\"" >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=2 delims=:" %%V in ("!LINE!") do (
                set "RAW=%%V"
                set "RAW=!RAW: =!"
                set "RAW=!RAW:"=!"
                set "RAW=!RAW:,=!"
                set "RAW=!RAW:}=!"
                if not "!RAW!"=="" (
                    if not "!RAW!"=="null" set "AKUNNAME=!RAW!"
                )
            )
        )
    )
)

:: Fallback ke nama folder jika nama tidak terbaca
if not defined AKUNNAME set "AKUNNAME=%PROFDIR%"

set "SCNAME=Chrome - !AKUNNAME!"
set "SCPATH=%DESKTOP%\!SCNAME!.lnk"

:: Buat shortcut via VBScript (paling stabil di semua versi Windows)
(
    echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
    echo Set oSC = oWS.CreateShortcut^("!SCPATH!"^)
    echo oSC.TargetPath = "!CHROME!"
    echo oSC.Arguments = "--profile-directory=""!PROFDIR!"""
    echo oSC.Description = "Chrome - !AKUNNAME!"
    echo oSC.Save
) > "%VBSTEMP%"

cscript //nologo "%VBSTEMP%" >nul 2>&1

if exist "!SCPATH!" (
    set /a BERHASIL+=1
    echo [BERHASIL] !SCNAME!.lnk   ^(folder: !PROFDIR!^)
) else (
    echo [GAGAL]    !SCNAME!.lnk
)

set "AKUNNAME="
exit /b
