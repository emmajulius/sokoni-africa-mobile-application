@echo off
echo ========================================
echo Getting SHA-1 Certificate Fingerprint
echo ========================================
echo.

echo Getting SHA-1 for DEBUG keystore...
echo.

keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr /C:"SHA1:"

echo.
echo ========================================
echo IMPORTANT: Copy the SHA-1 value above
echo (It should look like: AA:BB:CC:DD:EE:...)
echo ========================================
echo.
echo Next steps:
echo 1. Copy the SHA-1 fingerprint above
echo 2. Go to: https://console.cloud.google.com/apis/credentials
echo 3. Find your Android OAuth 2.0 Client ID
echo 4. Click Edit
echo 5. Paste the SHA-1 in the "SHA-1 certificate fingerprint" field
echo 6. Verify Package name: com.example.sokoni_africa_app
echo 7. Click Save
echo 8. Wait 5-10 minutes for changes to propagate
echo 9. Rebuild your app: flutter clean ^&^& flutter run
echo ========================================
echo.

pause
