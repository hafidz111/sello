enum ExportLanguage {
  id,
  en,
  ar,
  zh;

  String get code => name;

  String get label => switch (this) {
    id => 'Indonesia',
    en => 'English',
    ar => 'Arab',
    zh => 'Mandarin',
  };

  String get shortLabel => switch (this) {
    id => 'ID',
    en => 'EN',
    ar => 'AR',
    zh => 'ZH',
  };

  bool get isRtl => this == ar;
}
