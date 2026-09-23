class DocumentItem {
  final String id; // s3_key, used for all doc-specific endpoints

  final String displayName;

  final double sizeKb;

  final String date;

  final String status;

  final String? folder; // null/empty means root (unfiled)

  DocumentItem({
    required this.id,
    required this.displayName,
    required this.sizeKb,
    required this.date,
    required this.status,
    this.folder,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: json['id'],
        displayName: json['display_name'] ?? 'Encrypted document',
        sizeKb: (json['size_kb'] as num).toDouble(),
        date: json['date'] ?? '',
        status: json['status'] ?? '',
        folder: json['folder'],
      );
}