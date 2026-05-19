$ErrorActionPreference = 'Stop'

$src = Join-Path $env:USERPROFILE 'Downloads\export.geojson'
$repoRoot = Split-Path -Parent $PSScriptRoot
$out = Join-Path $repoRoot 'lib\core\constants\university_data.dart'
$json = Get-Content -Raw -Encoding UTF8 -Path $src | ConvertFrom-Json

function Escape-Dart([string]$s) {
  if ($null -eq $s) { return '' }
  return $s.Replace('\\', '\\\\').Replace("'", "\\'")
}

function Norm([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  return ($s -replace '\s+', ' ').Trim()
}

function Get-Coords($geom) {
  $script:coords = New-Object System.Collections.Generic.List[object]

  function Walk($node) {
    if ($null -eq $node) { return }

    if ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string])) {
      $arr = @($node)
      if ($arr.Count -eq 2) {
        $lon = 0.0
        $lat = 0.0
        $lonOk = [double]::TryParse(($arr[0]).ToString(), [ref]$lon)
        $latOk = [double]::TryParse(($arr[1]).ToString(), [ref]$lat)
        if ($lonOk -and $latOk) {
          $script:coords.Add(@($lon, $lat)) | Out-Null
          return
        }
      }

      foreach ($n in $arr) { Walk $n }
    }
  }

  Walk $geom.coordinates
  return $script:coords
}

function Split-UniCampus([string]$name, [string]$operator) {
  $name = Norm $name
  $operator = Norm $operator
  $uni = ''
  $campus = 'Ana Kampüs'

  if ([string]::IsNullOrWhiteSpace($name)) { $name = $operator }

  $tokens = @(' Üniversitesi', ' Universitesi', ' University', ' Enstitüsü', ' Enstitusu')
  $matched = $false

  foreach ($t in $tokens) {
    $idx = $name.IndexOf($t)
    if ($idx -ge 0) {
      $uni = Norm ($name.Substring(0, $idx + $t.Length))
      $rest = Norm ($name.Substring($idx + $t.Length)).Trim(' ', '-', ',')
      if ($rest) { $campus = $rest }
      $matched = $true
      break
    }
  }

  if (-not $matched) {
    if (-not [string]::IsNullOrWhiteSpace($operator)) {
      $uni = $operator
      $campus = $name
    } else {
      $uni = $name
    }
  }

  if ([string]::IsNullOrWhiteSpace($uni)) { return $null }
  return @($uni, $campus)
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($f in $json.features) {
  $p = $f.properties
  if ($p.amenity -ne 'university') { continue }

  $parsed = Split-UniCampus ([string]$p.name) ([string]$p.operator)
  if ($null -eq $parsed) { continue }

  $coords = Get-Coords $f.geometry
  if ($coords.Count -eq 0) { continue }

  $avgLon = ($coords | ForEach-Object { $_[0] } | Measure-Object -Average).Average
  $avgLat = ($coords | ForEach-Object { $_[1] } | Measure-Object -Average).Average

  if ($null -eq $avgLon -or $null -eq $avgLat) { continue }

  $rows.Add([pscustomobject]@{
      university = $parsed[0]
      campus = $parsed[1]
      latitude = [math]::Round([double]$avgLat, 6)
      longitude = [math]::Round([double]$avgLon, 6)
    }) | Out-Null
}

$grouped = $rows | Group-Object university
$mapLines = New-Object System.Collections.Generic.List[string]

foreach ($g in ($grouped | Sort-Object Name)) {
  $campusGroups = $g.Group | Group-Object campus

  $mapLines.Add("    '$(Escape-Dart $g.Name)': [") | Out-Null
  foreach ($cg in ($campusGroups | Sort-Object Name)) {
    $lat = [math]::Round((($cg.Group | Measure-Object latitude -Average).Average), 6)
    $lon = [math]::Round((($cg.Group | Measure-Object longitude -Average).Average), 6)
    $mapLines.Add("      const CampusData('$(Escape-Dart $cg.Name)', $lat, $lon),") | Out-Null
  }
  $mapLines.Add('    ],') | Out-Null
}

$header = @'
/// GeoJSON kaynağından türetilen üniversite/kampüs koordinat verisi.
class CampusData {
  final String name;
  final double latitude;
  final double longitude;

  const CampusData(this.name, this.latitude, this.longitude);
}

class UniversityData {
  /// Üniversite adı -> kampüs listesi.
  static final Map<String, List<CampusData>> universities = {
'@

$footer = @'
  };

  static String _normalize(String text) {
    const tr = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    final lower = text.toLowerCase().trim();
    final sb = StringBuffer();
    for (final ch in lower.split('')) {
      sb.write(tr[ch] ?? ch);
    }
    return sb.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> get universityNames {
    final names = universities.keys.toList()..sort();
    return names;
  }

  static List<String> searchUniversities(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return universityNames;
    return universityNames.where((u) => _normalize(u).contains(q)).toList();
  }

  static List<String> getCampusNames(String university) {
    return universities[university]?.map((c) => c.name).toList() ?? [];
  }

  static CampusData? getCampusData(String university, String? campus) {
    final list = universities[university];
    if (list == null || list.isEmpty) return null;
    if (campus == null || campus.trim().isEmpty) return list.first;

    final normalizedCampus = _normalize(campus);

    for (final c in list) {
      if (_normalize(c.name) == normalizedCampus) {
        return c;
      }
    }

    for (final c in list) {
      final cn = _normalize(c.name);
      if (cn.contains(normalizedCampus) || normalizedCampus.contains(cn)) {
        return c;
      }
    }

    return list.first;
  }
}
'@

$content = $header + ($mapLines -join "`r`n") + "`r`n" + $footer
Set-Content -Encoding UTF8 -Path $out -Value $content

Write-Host "Universite: $($grouped.Count)"
Write-Host "Kayit: $($rows.Count)"
