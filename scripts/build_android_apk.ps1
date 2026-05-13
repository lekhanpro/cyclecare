param(
  [ValidateSet("debug", "release")]
  [string]$Mode = "release",
  [string]$EnvFile = ".env.local"
)

$ErrorActionPreference = "Stop"

function Read-EnvFile {
  param([string]$Path)

  $values = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
    return $values
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
      continue
    }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Length -eq 2) {
      $values[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
    }
  }

  return $values
}

$config = Read-EnvFile -Path $EnvFile
$apiKey = $config["AI_API_KEY"]
$baseUrl = $config["AI_BASE_URL"]
$model = $config["AI_MODEL"]

if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw "AI_API_KEY is missing. Create $EnvFile from .env.example and add the key locally."
}

if ([string]::IsNullOrWhiteSpace($baseUrl) -and $apiKey.StartsWith("gsk_")) {
  $baseUrl = "https://api.groq.com/openai"
}

if ([string]::IsNullOrWhiteSpace($model) -and $apiKey.StartsWith("gsk_")) {
  $model = "llama-3.1-8b-instant"
}

if ([string]::IsNullOrWhiteSpace($baseUrl)) {
  $baseUrl = "https://api.openai.com"
}

if ([string]::IsNullOrWhiteSpace($model)) {
  $model = "gpt-4o-mini"
}

flutter pub get
flutter build apk "--$Mode" `
  "--dart-define=AI_API_KEY=$apiKey" `
  "--dart-define=AI_BASE_URL=$baseUrl" `
  "--dart-define=AI_MODEL=$model"
