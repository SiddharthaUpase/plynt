class DocumentModel {
  final String id;
  final String name;
  final String? tag;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final String userId;

  DocumentModel({
    required this.id,
    required this.name,
    this.tag,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    required this.userId,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      name: json['name'],
      tag: json['tag'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'file_url': fileUrl,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}
