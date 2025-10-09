import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class UploadDocumentPage extends StatefulWidget {
  final String applicationId;

  const UploadDocumentPage({super.key, required this.applicationId});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  File? _selectedFile;
  final picker = ImagePicker();
  final TextEditingController _docNameController = TextEditingController();
  bool isLoading = false;

  Future<void> _pickFile() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _docNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select file and document name.')),
      );
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.uploadDocument(
      applicationId: widget.applicationId,
      documentName: _docNameController.text,
      file: _selectedFile!,
    );

    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Upload completed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Document")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _docNameController,
              decoration: const InputDecoration(labelText: "Document Name"),
            ),
            const SizedBox(height: 20),
            _selectedFile == null
                ? const Text("No file selected")
                : Image.file(_selectedFile!, height: 150),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text("Choose File"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _uploadFile,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Upload Document"),
            ),
          ],
        ),
      ),
    );
  }
}
