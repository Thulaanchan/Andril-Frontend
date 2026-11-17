$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter 3.47.5 was not found on PATH.'
}
Push-Location (Join-Path $PSScriptRoot '..')
try {
  flutter pub get --enforce-lockfile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter gen-l10n
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}
