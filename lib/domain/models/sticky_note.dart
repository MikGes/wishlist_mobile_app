import 'dart:convert';

class StickyNoteStyle {
  const StickyNoteStyle({
    required this.colorHex,
    required this.fontSize,
    required this.fontFamily,
    required this.layout,
  });

  final int colorHex;
  final double fontSize;
  final String fontFamily;
  final String layout; // bullet | paragraph

  Map<String, Object?> toJson() => {
        'colorHex': colorHex,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'layout': layout,
      };

  static StickyNoteStyle fromJson(Map<String, Object?> json) {
    return StickyNoteStyle(
      colorHex: (json['colorHex'] as num?)?.toInt() ?? 0xFFFFF3B0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      fontFamily: (json['fontFamily'] as String?) ?? 'Roboto',
      layout: (json['layout'] as String?) ?? 'bullet',
    );
  }

  String toDb() => jsonEncode(toJson());
  static StickyNoteStyle fromDb(String raw) =>
      fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
}

class StickyNote {
  const StickyNote({
    required this.id,
    required this.content,
    required this.style,
    required this.createdAt,
  });

  final String id;
  final String content;
  final StickyNoteStyle style;
  final DateTime createdAt;

  StickyNote copyWith({
    String? content,
    StickyNoteStyle? style,
  }) {
    return StickyNote(
      id: id,
      content: content ?? this.content,
      style: style ?? this.style,
      createdAt: createdAt,
    );
  }

  static StickyNote fromRow(Map<String, Object?> row) {
    return StickyNote(
      id: row['id'] as String,
      content: row['content'] as String,
      style: StickyNoteStyle.fromDb(row['style'] as String),
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'content': content,
      'style': style.toDb(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

