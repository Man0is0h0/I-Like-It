class LinkItem {
  final int? id;
  final int folderId;
  final String url;
  final String title;
  final String? domain;
  final String? imageUrl;
  final String? notes;
  final String? folderName;
  final DateTime createdAt;

  LinkItem({
    this.id,
    required this.folderId,
    required this.url,
    required this.title,
    this.domain,
    this.imageUrl,
    this.notes,
    this.folderName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_id': folderId,
      'url': url,
      'title': title,
      'domain': domain,
      'image_url': imageUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      // We typically do not save folderName back to DB, it's just for UI
    };
  }

  factory LinkItem.fromMap(Map<String, dynamic> map) {
    return LinkItem(
      id: map['id'],
      folderId: map['folder_id'],
      url: map['url'],
      title: map['title'],
      domain: map['domain'],
      imageUrl: map['image_url'],
      notes: map['notes'],
      folderName: map['folder_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
