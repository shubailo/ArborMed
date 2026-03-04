import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/quote.dart';

void main() {
  group('Quote.fromJson', () {
    test('parses fully populated JSON correctly', () {
      final json = {
        'id': 10,
        'text_en': 'Never give up.',
        'text_hu': 'Soha ne add fel.',
        'author': 'Winston Churchill',
        'title_en': 'Motivation',
        'title_hu': 'Motiváció',
        'icon_name': 'star',
        'custom_icon_url': 'https://example.com/icon.png',
        'created_at': '2023-10-27T10:00:00Z',
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 10);
      expect(quote.textEn, 'Never give up.');
      expect(quote.textHu, 'Soha ne add fel.');
      expect(quote.author, 'Winston Churchill');
      expect(quote.titleEn, 'Motivation');
      expect(quote.titleHu, 'Motiváció');
      expect(quote.iconName, 'star');
      expect(quote.customIconUrl, 'https://example.com/icon.png');
      expect(quote.createdAt, DateTime.parse('2023-10-27T10:00:00Z'));
    });

    test('falls back to "text" if "text_en" is missing', () {
      final json = {
        'id': 1,
        'text': 'A good quote.',
        'text_hu': 'Egy jó idézet.',
        'author': 'Someone',
      };

      final quote = Quote.fromJson(json);

      expect(quote.textEn, 'A good quote.');
    });

    test('defaults to empty string if neither "text_en" nor "text" is present', () {
      final json = {
        'id': 2,
        'author': 'Anonymous',
      };

      final quote = Quote.fromJson(json);

      expect(quote.textEn, '');
    });

    test('applies default values for missing optional fields', () {
      final json = {
        'id': 3,
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 3);
      expect(quote.textEn, '');
      expect(quote.textHu, '');
      expect(quote.author, 'Anonymous');
      expect(quote.titleEn, 'Study Break');
      expect(quote.titleHu, 'Tanulás');
      expect(quote.iconName, 'menu_book_rounded');
      expect(quote.customIconUrl, isNull);
      expect(quote.createdAt, isNull);
    });

    test('handles missing id with default 0', () {
      final json = <String, dynamic>{
        'text_en': 'No ID here',
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 0);
      expect(quote.textEn, 'No ID here');
    });

    test('parses null created_at correctly', () {
      final json = {
        'id': 4,
        'created_at': null,
      };

      final quote = Quote.fromJson(json);

      expect(quote.createdAt, isNull);
    });
  });
}
