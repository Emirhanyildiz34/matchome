import 'dart:convert';
import 'dart:io';

class _CampusPoint {
  final String university;
  final String campus;
  final double lat;
  final double lon;

  const _CampusPoint({
    required this.university,
    required this.campus,
    required this.lat,
    required this.lon,
  });
}

bool _containsUniversityKeyword(String? text) {
  if (text == null) return false;
  final t = text.toLowerCase();
  return t.contains('ünivers') ||
      t.contains('universit') ||
      t.contains('university') ||
      t.contains('enstitü') ||
      t.contains('enstitu');
}

String _normalizeWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

({String university, String campus})? _parseUniversityCampus(
  String? name,
  String? operator,
) {
  final n = _normalizeWhitespace(name ?? '');
  final o = _normalizeWhitespace(operator ?? '');

  if (!_containsUniversityKeyword(n) && !_containsUniversityKeyword(o)) {
    return null;
  }

  final source = n.isNotEmpty ? n : o;

  final lower = source.toLowerCase();
  final splitTokens = <String>[' üniversitesi', ' university', ' enstitüsü', ' enstitusu'];

  for (final token in splitTokens) {
    final idx = lower.indexOf(token);
    if (idx >= 0) {
      final end = idx + token.length;
      final university = _normalizeWhitespace(source.substring(0, end));
      final rest = _normalizeWhitespace(source.substring(end))
          .replaceAll(RegExp(r'^[\-–—,\s]+|[\-–—,\s]+$'), '')
          .trim();
      final campus = rest.isEmpty ? 'Ana Kampüs' : rest;
      if (university.isNotEmpty) {
        return (university: university, campus: campus);
      }
    }
  }

  if (_containsUniversityKeyword(o)) {
    return (
      university: o,
      campus: n.isNotEmpty ? n : 'Ana Kampüs',
    );
  }

  return (
    university: source,
    campus: 'Ana Kampüs',
  );
}

void _collectCoords(dynamic node, List<List<double>> out) {
  if (node is List) {
    if (node.length == 2 && node[0] is num && node[1] is num) {
      out.add([(node[0] as num).toDouble(), (node[1] as num).toDouble()]);
      return;
    }
    for (final child in node) {
      _collectCoords(child, out);
    }
  }
}

List<double>? _centroid(dynamic geometry) {
  if (geometry is! Map<String, dynamic>) return null;
  final coords = <List<double>>[];
  _collectCoords(geometry['coordinates'], coords);
  if (coords.isEmpty) return null;

  double sumLon = 0;
  double sumLat = 0;
  for (final c in coords) {
    sumLon += c[0];
    sumLat += c[1];
  }
  return [sumLat / coords.length, sumLon / coords.length];
}

String _escapeDart(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _normalizeText(String text) {
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

void main() {
  final home = Platform.environment['USERPROFILE'] ?? '';
  final src = File('$home\\Downloads\\export.geojson');
  final out = File('lib/core/constants/university_data.dart');

  if (!src.existsSync()) {
    stderr.writeln('Kaynak dosya bulunamadı: ${src.path}');
    exit(1);
  }

  final raw = src.readAsBytesSync();
  final jsonData = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
  final features = (jsonData['features'] as List<dynamic>).cast<Map<String, dynamic>>();

  final points = <_CampusPoint>[];

  for (final feature in features) {
    final props = (feature['properties'] as Map<String, dynamic>? ?? const {});
    if ((props['amenity']?.toString() ?? '') != 'university') continue;

    final parsed = _parseUniversityCampus(
      props['name']?.toString(),
      props['operator']?.toString(),
    );
    if (parsed == null) continue;

    final center = _centroid(feature['geometry']);
    if (center == null) continue;

    points.add(_CampusPoint(
      university: parsed.university,
      campus: parsed.campus,
      lat: center[0],
      lon: center[1],
    ));
  }

  final byUniversity = <String, Map<String, List<_CampusPoint>>>{};
  for (final p in points) {
    byUniversity.putIfAbsent(p.university, () => {});
    byUniversity[p.university]!.putIfAbsent(p.campus, () => []);
    byUniversity[p.university]![p.campus]!.add(p);
  }

  final universities = byUniversity.keys.toList()..sort((a, b) => a.compareTo(b));

  final b = StringBuffer();
  b.writeln('/// GeoJSON kaynağından türetilen üniversite/kampüs koordinat verisi.');
  b.writeln('class CampusData {');
  b.writeln('  final String name;');
  b.writeln('  final double latitude;');
  b.writeln('  final double longitude;');
  b.writeln();
  b.writeln('  const CampusData(this.name, this.latitude, this.longitude);');
  b.writeln('}');
  b.writeln();
  b.writeln('class UniversityData {');
  b.writeln('  /// Üniversite adı -> kampüs listesi.');
  b.writeln('  static final Map<String, List<CampusData>> universities = {');

  for (final uni in universities) {
    b.writeln("    '${_escapeDart(uni)}': [");
    final campuses = byUniversity[uni]!.keys.toList()..sort((a, b) => a.compareTo(b));
    for (final campus in campuses) {
      final list = byUniversity[uni]![campus]!;
      final avgLat = list.map((e) => e.lat).reduce((a, b) => a + b) / list.length;
      final avgLon = list.map((e) => e.lon).reduce((a, b) => a + b) / list.length;
      b.writeln(
          "      const CampusData('${_escapeDart(campus)}', ${avgLat.toStringAsFixed(6)}, ${avgLon.toStringAsFixed(6)}),");
    }
    b.writeln('    ],');
  }

  b.writeln('  };');
  b.writeln();
  b.writeln('  static String _normalize(String text) {');
  b.writeln('    const tr = {');
  b.writeln("      'ç': 'c',");
  b.writeln("      'ğ': 'g',");
  b.writeln("      'ı': 'i',");
  b.writeln("      'i': 'i',");
  b.writeln("      'ö': 'o',");
  b.writeln("      'ş': 's',");
  b.writeln("      'ü': 'u',");
  b.writeln('    };');
  b.writeln('    final lower = text.toLowerCase().trim();');
  b.writeln('    final sb = StringBuffer();');
  b.writeln("    for (final ch in lower.split('')) {");
  b.writeln('      sb.write(tr[ch] ?? ch);');
  b.writeln('    }');
  b.writeln("    return sb.toString().replaceAll(RegExp(r'\\s+'), ' ');");
  b.writeln('  }');
  b.writeln();
  b.writeln('  static List<String> get universityNames {');
  b.writeln('    final names = universities.keys.toList()..sort();');
  b.writeln('    return names;');
  b.writeln('  }');
  b.writeln();
  b.writeln('  static List<String> searchUniversities(String query) {');
  b.writeln('    final q = _normalize(query);');
  b.writeln('    if (q.isEmpty) return universityNames;');
  b.writeln('    return universityNames.where((u) => _normalize(u).contains(q)).toList();');
  b.writeln('  }');
  b.writeln();
  b.writeln('  static List<String> getCampusNames(String university) {');
  b.writeln('    return universities[university]?.map((c) => c.name).toList() ?? [];');
  b.writeln('  }');
  b.writeln();
  b.writeln('  static CampusData? getCampusData(String university, String? campus) {');
  b.writeln('    final list = universities[university];');
  b.writeln('    if (list == null || list.isEmpty) return null;');
  b.writeln('    if (campus == null || campus.trim().isEmpty) return list.first;');
  b.writeln();
  b.writeln('    final normalizedCampus = _normalize(campus);');
  b.writeln();
  b.writeln('    for (final c in list) {');
  b.writeln('      if (_normalize(c.name) == normalizedCampus) {');
  b.writeln('        return c;');
  b.writeln('      }');
  b.writeln('    }');
  b.writeln();
  b.writeln('    for (final c in list) {');
  b.writeln('      final cn = _normalize(c.name);');
  b.writeln('      if (cn.contains(normalizedCampus) || normalizedCampus.contains(cn)) {');
  b.writeln('        return c;');
  b.writeln('      }');
  b.writeln('    }');
  b.writeln();
  b.writeln('    return list.first;');
  b.writeln('  }');
  b.writeln('}');

  out.writeAsStringSync(b.toString(), encoding: utf8);

  stdout.writeln('Universite: ${universities.length}');
  stdout.writeln('Kayit: ${points.length}');
}
