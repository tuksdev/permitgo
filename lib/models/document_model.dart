// lib/models/document_model.dart

class DocumentRequirement {
  final String documentName;
  final String documentCode;
  bool isUploaded;

  DocumentRequirement({
    required this.documentName,
    required this.documentCode,
    this.isUploaded = false,
  });
}