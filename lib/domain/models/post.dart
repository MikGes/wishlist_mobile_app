class Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;

  static Post fromRow(Map<String, Object?> row) {
    return Post(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      category: row['category'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };
}

