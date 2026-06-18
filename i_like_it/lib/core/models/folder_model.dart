class Folder {
  final int? id;
  final String name;
  final DateTime createdAt;
  final String icon; // Icon codepoint as string (e.g., '0xe3b0' for folder icon)
  final int itemCount;

  Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.icon = '0xe3b0', // Default folder icon
    this.itemCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'icon': icon,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      icon: map['icon'] ?? '0xe3b0',
      itemCount: map['item_count'] as int? ?? 0,
    );
  }
}
