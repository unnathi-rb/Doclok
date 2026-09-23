class FolderItem {
  final String name;
  final int docCount;

  FolderItem({
    required this.name,
    required this.docCount,
  });

  factory FolderItem.fromJson(Map<String, dynamic> json) => FolderItem(
        name: json['name'],
        docCount: json['doc_count'] ?? 0,
      );
}