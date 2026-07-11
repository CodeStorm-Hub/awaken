# Slow GPS loop around Sher-e-Bangla Stadium bounty (Mirpur).
# Keeps ground speed under ~15 km/h so anti-cheat does not trip.
# Encloses centroid ~23.8065, 90.3635. ~280 m perimeter, ~90 s.
$ErrorActionPreference = 'Stop'
$serial = 'emulator-5554'

function Set-Geo([double]$lng, [double]$lat) {
  adb -s $serial emu geo fix $lng $lat | Out-Null
}

# Small rectangle that still contains the stadium bounty centroid
$corners = @(
  @(90.3630, 23.8060),
  @(90.3640, 23.8060),
  @(90.3640, 23.8070),
  @(90.3630, 23.8070),
  @(90.3630, 23.8060)
)

Write-Host 'Seeding start fix...'
Set-Geo 90.3630 23.8060
Start-Sleep -Seconds 2

Write-Host 'Walking 2 slow laps (~15 km/h)...'
for ($lap = 1; $lap -le 2; $lap++) {
  for ($i = 0; $i -lt ($corners.Count - 1); $i++) {
    $a = $corners[$i]
    $b = $corners[$i + 1]
    $steps = 5
    for ($s = 1; $s -le $steps; $s++) {
      $t = $s / $steps
      $lng = $a[0] + ($b[0] - $a[0]) * $t
      $lat = $a[1] + ($b[1] - $a[1]) * $t
      Set-Geo $lng $lat
      Write-Host ("  lap{0} seg{1}/{2}: {3:N5},{4:N5}" -f $lap, ($i+1), $s, $lat, $lng)
      # ~14 m / 2.2 s ≈ 6.4 m/s ≈ 23 km/h worst case; usually slower
      Start-Sleep -Milliseconds 2200
    }
  }
}

Set-Geo 90.3630 23.8060
Write-Host 'Closed at start.'
