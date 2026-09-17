@echo off
echo ======================================================================
echo BUILDING NAVRATRI UTSAV - COMPRESSED HYBRID ANDROID APK
echo ======================================================================
echo.

call flutter build apk --release --split-per-abi
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Split-per-abi build returned an error. Retrying standard universal APK build...
    call flutter build apk --release
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Hybrid APK build failed!
        pause
        exit /b %ERRORLEVEL%
    )
)

if not exist "dist\Android_Hybrid" mkdir "dist\Android_Hybrid"
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "dist\Android_Hybrid\Navratri_Hybrid.apk"
)
if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "dist\Android_Hybrid\Navratri_Hybrid.apk"
    copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "dist\Android_Hybrid\Navratri_Hybrid_arm64.apk"
)
if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "dist\Android_Hybrid\Navratri_Hybrid_armeabi_v7a.apk"
)

echo.
echo ======================================================================
echo COMPRESSED HYBRID APK READY: dist\Android_Hybrid\Navratri_Hybrid.apk
echo ======================================================================
pause
