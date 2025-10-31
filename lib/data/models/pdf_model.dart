import 'package:cloud_firestore/cloud_firestore.dart';

class PDFModel {
  final String id;
  final String name;
  final String url;
  final DateTime uploadDate;
  final int size;
  final String? userId;

  PDFModel({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadDate,
    required this.size,
    this.userId,
  });

  factory PDFModel.fromMap(Map<String, dynamic> map) {
    return PDFModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
      size: map['size'] ?? 0,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'size': size,
      'userId': userId,
    };
  }
}
