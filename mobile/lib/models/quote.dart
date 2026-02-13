class Quote {
  final int id;
  final String textEn;
  final String textHu;
  final String author;
  final String titleEn;
  final String titleHu;
  final String iconName;
  final String? customIconUrl;
  final DateTime? createdAt;

  Quote({
    required this.id,
    required this.textEn,
    required this.textHu,
    required this.author,
    this.titleEn = 'Study Break',
    this.titleHu = 'Tanulás',
    this.iconName = 'menu_book_rounded',
    this.customIconUrl,
    this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      textEn: json['text_en'] ?? json['text'] ?? '',
      textHu: json['text_hu'] ?? '',
      author: json['author'] ?? 'Anonymous',
      titleEn: json['title_en'] ?? 'Study Break',
      titleHu: json['title_hu'] ?? 'Tanulás',
      iconName: json['icon_name'] ?? 'menu_book_rounded',
      customIconUrl: json['custom_icon_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
