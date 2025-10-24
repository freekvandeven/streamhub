# Troubleshooting

## CORS Error on Web

Web browsers block requests to servers without CORS headers.

**Solution**: Use mobile/desktop apps, or run Chrome with:
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

## Playlist Won't Load

- Check your `dotenv` file has `PLAYLIST_URL` set
- Verify the URL is accessible
- Try on mobile/desktop instead of web
