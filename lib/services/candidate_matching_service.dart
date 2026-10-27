part of '../../main.dart';

class CandidateMatchingService {
  static const _stopwords = {
    'ada',
    'adalah',
    'akan',
    'atau',
    'barang',
    'buah',
    'dalam',
    'dan',
    'dari',
    'dengan',
    'dekat',
    'di',
    'ditemukan',
    'hilang',
    'ini',
    'itu',
    'kampus',
    'ke',
    'mahasiswa',
    'malang',
    'pada',
    'saya',
    'sebuah',
    'sekitar',
    'temuan',
    'uin',
    'untuk',
    'warna',
    'yang',
  };

  static const _synonyms = {
    'hp': 'handphone',
    'ponsel': 'handphone',
    'telepon': 'handphone',
    'ransel': 'tas',
  };

  List<ReportMatch> findMatches({
    required BarangItem target,
    required Iterable<BarangItem> candidates,
    int limit = 3,
    double minimumScore = 0.42,
  }) {
    if (target.status == StatusBarang.selesai || limit <= 0) return const [];

    final targetProfile = _MatchProfile.from(target);
    final matches = <ReportMatch>[];

    for (final candidate in candidates) {
      if (!_bolehDibandingkan(target, candidate)) continue;

      final candidateProfile = _MatchProfile.from(candidate);
      final nameScore =
          _dice(targetProfile.namaTokens, candidateProfile.namaTokens);
      final descriptionScore = _dice(
        targetProfile.deskripsiTokens,
        candidateProfile.deskripsiTokens,
      );
      final textScore = (nameScore * .6) + (descriptionScore * .4);
      if (textScore < .05) continue;

      final locationScore = _locationScore(targetProfile, candidateProfile);
      final timeScore = _timeScore(target.tanggal, candidate.tanggal);
      final score =
          (textScore * .6) + (locationScore * .25) + (timeScore * .15);
      if (score < minimumScore) continue;

      final reasons = <String>[];
      if (nameScore >= .45) {
        reasons.add('Nama barang mirip');
      } else if (textScore >= .45) {
        reasons.add('Deskripsi mirip');
      }
      if (locationScore >= .6) reasons.add('Lokasi berdekatan');
      if (timeScore >= .6) reasons.add('Waktu berdekatan');
      if (reasons.isEmpty) reasons.add('Kata kunci mirip');

      matches.add(ReportMatch(
        report: candidate,
        score: score.clamp(0, 1).toDouble(),
        reasons: reasons,
      ));
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byTime = _hourDistance(a.report.tanggal, target.tanggal)
          .compareTo(_hourDistance(b.report.tanggal, target.tanggal));
      if (byTime != 0) return byTime;
      return a.report.id.compareTo(b.report.id);
    });
    return List.unmodifiable(matches.take(limit));
  }

  bool _bolehDibandingkan(BarangItem target, BarangItem candidate) {
    if (identical(candidate, target)) return false;
    if (candidate.id.isNotEmpty && candidate.id == target.id) return false;
    if (candidate.jenis == target.jenis) return false;
    if (candidate.status == StatusBarang.selesai) return false;

    final targetOwner = target.pemilikEmail?.trim().toLowerCase();
    final candidateOwner = candidate.pemilikEmail?.trim().toLowerCase();
    if (targetOwner != null &&
        targetOwner.isNotEmpty &&
        targetOwner == candidateOwner) {
      return false;
    }
    return true;
  }

  double _locationScore(_MatchProfile target, _MatchProfile candidate) {
    if (target.lokasi.isEmpty || candidate.lokasi.isEmpty) return 0;
    if (target.lokasi == candidate.lokasi) return 1;
    if (target.lokasi.contains(candidate.lokasi) ||
        candidate.lokasi.contains(target.lokasi)) {
      return .85;
    }
    return _dice(target.lokasiTokens, candidate.lokasiTokens) * .7;
  }

  double _timeScore(DateTime target, DateTime candidate) {
    final hours = _hourDistance(target, candidate);
    if (hours <= 24) return 1;
    if (hours <= 72) return .8;
    if (hours <= 168) return .6;
    if (hours <= 720) return .3;
    return 0;
  }

  int _hourDistance(DateTime a, DateTime b) => a.difference(b).inHours.abs();

  double _dice(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    var intersection = 0;
    for (final token in a) {
      if (b.contains(token)) intersection++;
    }
    return (2 * intersection) / (a.length + b.length);
  }
}

class _MatchProfile {
  final Set<String> namaTokens;
  final Set<String> deskripsiTokens;
  final Set<String> lokasiTokens;
  final String lokasi;

  const _MatchProfile({
    required this.namaTokens,
    required this.deskripsiTokens,
    required this.lokasiTokens,
    required this.lokasi,
  });

  factory _MatchProfile.from(BarangItem item) {
    final nama = _normalisasi(item.nama);
    final deskripsi = _normalisasi(item.deskripsi);
    final lokasi = _normalisasi(item.lokasi);
    return _MatchProfile(
      namaTokens: _tokens(nama),
      deskripsiTokens: _tokens(deskripsi),
      lokasiTokens: _tokens(lokasi),
      lokasi: lokasi,
    );
  }

  static String _normalisasi(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static Set<String> _tokens(String value) {
    final result = <String>{};
    for (final raw in value.split(' ')) {
      if (raw.isEmpty || CandidateMatchingService._stopwords.contains(raw)) {
        continue;
      }
      result.add(CandidateMatchingService._synonyms[raw] ?? raw);
    }
    return result;
  }
}
