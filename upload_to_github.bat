@echo off
echo ======================================================================
echo UPLOADING NAVRATRI UTSAV APP TO GITHUB
echo ======================================================================
echo.

cd /d "e:\navratri"

echo Pushing main branch to: https://github.com/yvpdevelopments9232-cpu/Navratri.git
echo.
git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [NOTE] If repository has existing files, retrying with force push...
    git push -f -u origin main
)

echo.
echo ======================================================================
echo UPLOAD COMPLETED!
echo Check your repository: https://github.com/yvpdevelopments9232-cpu/Navratri
echo Check iOS/macOS builds in: https://github.com/yvpdevelopments9232-cpu/Navratri/actions
echo ======================================================================
pause
