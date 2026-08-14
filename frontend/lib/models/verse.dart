class Verse {
  final int ayahId;
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String textArabic;
  final String translationEn;
  final String reference;
  final Tafsir? tafsir;
  final SufiInsights? sufi;
  final double? relevanceScore;

  Verse({
    required this.ayahId,
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.textArabic,
    required this.translationEn,
    required this.reference,
    this.tafsir,
    this.sufi,
    this.relevanceScore,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      ayahId: json['ayah_id'] ?? 0,
      surahNumber: json['surah_number'] ?? 0,
      surahName: json['surah_name'] ?? '',
      verseNumber: json['verse_number'] ?? 0,
      textArabic: json['text_arabic'] ?? '',
      translationEn: json['translation_en'] ?? '',
      reference: json['reference'] ?? '',
      tafsir: json['tafsir'] != null ? Tafsir.fromJson(json['tafsir']) : null,
      sufi: json['sufi'] != null ? SufiInsights.fromJson(json['sufi']) : null,
      relevanceScore: json['relevance_score']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ayah_id': ayahId,
      'surah_number': surahNumber,
      'surah_name': surahName,
      'verse_number': verseNumber,
      'text_arabic': textArabic,
      'translation_en': translationEn,
      'reference': reference,
      'tafsir': tafsir?.toJson(),
      'sufi': sufi?.toJson(),
      'relevance_score': relevanceScore,
    };
  }
}

class Tafsir {
  final String? ibnKathir;
  final String? jalalayn;

  Tafsir({this.ibnKathir, this.jalalayn});

  factory Tafsir.fromJson(Map<String, dynamic> json) {
    return Tafsir(
      ibnKathir: json['ibn_kathir'],
      jalalayn: json['jalalayn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ibn_kathir': ibnKathir,
      'jalalayn': jalalayn,
    };
  }
}

class SufiInsights {
  final String? rumi;
  final String? ibnArabi;

  SufiInsights({this.rumi, this.ibnArabi});

  factory SufiInsights.fromJson(Map<String, dynamic> json) {
    return SufiInsights(
      rumi: json['rumi'],
      ibnArabi: json['ibn_arabi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rumi': rumi,
      'ibn_arabi': ibnArabi,
    };
  }
}