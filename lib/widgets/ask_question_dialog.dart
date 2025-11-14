// lib/widgets/ask_question_dialog.dart

import 'package:flutter/material.dart';

class AskQuestionDialog extends StatefulWidget {
  const AskQuestionDialog({super.key});

  @override
  State<AskQuestionDialog> createState() => _AskQuestionDialogState();
}

class _AskQuestionDialogState extends State<AskQuestionDialog> {
  final _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // --- Submission Logic Placeholder ---
  void _submitQuestion() async {
    final question = _questionController.text.trim();
    
    if (question.isEmpty) {
      // Basic validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your question.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 🛑 INTEGRATION POINT: 
    // Here, you would typically call your API or database 
    // service (e.g., Firebase Firestore, a custom backend) 
    // to submit the question to the admin.

    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // After successful (or failed) submission
    setState(() {
      _isSubmitting = false;
    });

    // Show confirmation and close the dialog
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Your question has been submitted to the admin!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ask the Admin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'If you can\'t find the answer in the FAQs, submit your question here. An admin will respond shortly.',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Your Question',
                hintText: 'e.g., How do I update my profile picture?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2B47),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}