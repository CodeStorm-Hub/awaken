#Requires -Version 5.1
<#
.SYNOPSIS
  Sets FIREBASE_SERVICE_ACCOUNT on the Awaken Supabase project for FCM HTTP v1.

.DESCRIPTION
  Uses the firebase-adminsdk key under %TEMP%\awaken-fcm\, or regenerates one.
  Requires a valid personal access token (Account → Access Tokens).

.EXAMPLE
  $env:SUPABASE_ACCESS_TOKEN = 'sbp_...'
  .\scripts\set-firebase-fcm-secret.ps1
#>
$ErrorActionPreference = 'Stop'
$ProjectRef = 'nankdbntvvopnfvvvaoo'
$ProjectId = 'awaken-27f39'
$SaEmail = 'firebase-adminsdk-fbsvc@awaken-27f39.iam.gserviceaccount.com'
$KeyPath = Join-Path $env:TEMP 'awaken-fcm\firebase-adminsdk.json'

if (-not $env:SUPABASE_ACCESS_TOKEN) {
  Write-Error 'Set SUPABASE_ACCESS_TOKEN first (https://supabase.com/dashboard/account/tokens)'
}

if (-not (Test-Path $KeyPath)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $KeyPath) | Out-Null
  gcloud config set project $ProjectId | Out-Null
  gcloud iam service-accounts keys create $KeyPath --iam-account=$SaEmail --project=$ProjectId
}

$compact = (Get-Content -Raw $KeyPath | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 20)
npx supabase secrets set "FIREBASE_SERVICE_ACCOUNT=$compact" --project-ref $ProjectRef
npx supabase secrets list --project-ref $ProjectRef
Write-Host "Do not commit $KeyPath"
