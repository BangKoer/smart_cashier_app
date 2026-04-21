# Windows Release Runbook (Flutter + Node Backend)

This guide packages the app so users can click one `.exe` and run frontend + backend together.

## 1) Prerequisites

- Flutter SDK installed and Windows desktop enabled
- Node.js installed on build machine
- Project backend health endpoint available in `server/index.js`:

```js
app.get("/api/health", (req, res) => {
  res.status(200).json({ ok: true });
});
```

- Flutter base URL points to local backend (recommended):

`lib/constant/global_variables.dart`

```dart
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://127.0.0.1:3000',
);
```

## 2) Build Backend Dependencies (production only)

Run in PowerShell from project root:

```powershell
cd server
npm ci --omit=dev
cd ..
```

## 3) Build Flutter Windows Release

```powershell
flutter build windows --release
```

Output folder:

`build\windows\x64\runner\Release`

## 4) Prepare `dist_backend` beside exe

Run from project root:

```powershell
$releaseDir = "build\windows\x64\runner\Release"
$backendDir = Join-Path $releaseDir "dist_backend"
New-Item -ItemType Directory -Force -Path $backendDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $backendDir "server") | Out-Null
```

Running these multiple times is safe.

## 5) Copy Backend Files

```powershell
Copy-Item server\index.js (Join-Path $backendDir "server\index.js") -Force
Copy-Item server\database.js (Join-Path $backendDir "server\database.js") -Force
Copy-Item server\package.json (Join-Path $backendDir "server\package.json") -Force
Copy-Item server\models (Join-Path $backendDir "server\models") -Recurse -Force
Copy-Item server\routes (Join-Path $backendDir "server\routes") -Recurse -Force
Copy-Item server\middlewares (Join-Path $backendDir "server\middlewares") -Recurse -Force
Copy-Item server\node_modules (Join-Path $backendDir "server\node_modules") -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $backendDir "server\uploads\invoices") | Out-Null
```

## 6) Copy Node Runtime (`node.exe`)

Find Node path:

```powershell
where.exe node
```

Copy `node.exe` to `dist_backend`:

```powershell
Copy-Item "C:\Path\To\node.exe" (Join-Path $backendDir "node.exe") -Force
```

Replace `C:\Path\To\node.exe` with your real path from `where.exe node`.

## 7) Smoke Test the Packaged App

```powershell
cd build\windows\x64\runner\Release
.\smart_cashier_app.exe
```

Expected:

- App opens normally
- Backend starts automatically
- API calls work (`/api/health` reachable)

## 8) Optional: Zip for Distribution

From project root:

```powershell
Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath smart_pos_windows_release.zip -Force
```

## Troubleshooting

### A) Upload path error (`server\server\uploads...`)

Use absolute upload path in `server/routes/PurchasedReceipt.js` based on `__dirname`.

### B) Backend not starting in packaged app

- Verify `dist_backend\node.exe` exists
- Verify `dist_backend\server\index.js` exists
- Verify `node_modules` was copied
- Verify MySQL is reachable from target machine

### C) API returns HTML instead of JSON

Usually backend is down or wrong URL. Confirm `baseUrl` is `http://127.0.0.1:3000` for packaged app.

## Repeatable Release Checklist

1. `npm ci --omit=dev` in `server`
2. `flutter build windows --release`
3. Recreate `dist_backend`
4. Copy backend files + `node.exe`
5. Smoke test `.exe`
6. Zip output (optional)

