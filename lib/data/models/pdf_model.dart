import 'package:cloud_firestore/cloud_firestore.dart';

class PDFModel {
  final String id;
  final String name;
  final String url;
  final DateTime uploadDate;
  final int size;
  final String userId;

  PDFModel({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadDate,
    required this.size,
    required this.userId,
  });

  factory PDFModel.fromMap(Map<String, dynamic> map) {
    // Manejar diferentes formatos de fecha
    Timestamp uploadDate;
    if (map['uploadDate'] is Timestamp) {
      uploadDate = map['uploadDate'] as Timestamp;
    } else if (map['uploadDate'] is String) {
      uploadDate = Timestamp.fromDate(DateTime.parse(map['uploadDate']));
    } else {
      uploadDate = Timestamp.now();
    }

    // Manejar diferentes formatos de tamaño
    int size;
    if (map['size'] is int) {
      size = map['size'] as int;
    } else if (map['size'] is String) {
      size = int.tryParse(map['size']) ?? 0;
    } else {
      size = 0;
    }

    return PDFModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Sin nombre',
      url: map['url']?.toString() ?? '',
      uploadDate: uploadDate.toDate(),
      size: size,
      userId: map['userId']?.toString() ?? '',
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

  @override
  String toString() {
    return 'PDFModel{id: $id, name: $name, size: $size, userId: $userId}';
  }
}
