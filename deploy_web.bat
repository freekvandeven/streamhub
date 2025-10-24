@echo off
echo Building Flutter web app...
flutter build web --release

echo.
echo Deploying to Firebase Hosting...
firebase deploy --only hosting

echo.
echo Deployment complete!
echo Visit: https://streamhub-pro.web.app
