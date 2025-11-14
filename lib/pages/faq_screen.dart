// lib/pages/faq_screen.dart

import 'package:flutter/material.dart';
import '../widgets/ask_question_dialog.dart'; // Ensure this import path is correct

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // --- FAQ Data Structure (Static Data) ---
  final List<Map<String, String>> _faqList = const [
    {
      'question': 'How do I start a new business application?',
      'answer': 'Navigate to the Home screen and select "New Application". Fill in all required details across the multi-step form (Taxpayer, Other Information, Business Activity) and submit.',
    },
    {
      'question': 'How do I renew my existing business permit?',
      'answer': 'Go to the Renewal screen, select your approved business from the list, review and update any changed information (address, contact, activity), submit the renewal form, and then proceed to upload the necessary renewal documents.',
    },
    {
      'question': 'What file types are accepted for document upload?',
      'answer': 'The system currently accepts files in PDF, JPG, JPEG, and PNG formats. Please ensure documents are clear and legible.',
    },
    {
      'question': 'Why am I seeing "No approved businesses found" in the renewal section?',
      'answer': 'This usually means your previous applications are still in "Pending Review" or "Draft" status, or the business permit has expired. Only applications marked "Approved" are visible for renewal.',
    },
    {
      'question': 'How can I pay for my permit application?',
      'answer': 'Once your application is reviewed and approved, you will be directed to the payment gateway. You can pay via Gcash, Maya, or any major credit/debit card.',
    },
    {
      'question': 'How long does the application review process take?',
      'answer': 'The standard review time is typically 3-5 business days after all necessary documents have been successfully uploaded and verified.',
    },
    {
      'question': 'Where can I check the status of my application?',
      'answer': 'You can check the status of all applications (New, Renewal, Retirement) on your main Dashboard or Application History screen.',
    },
    {
      'question': 'The app is showing a network error. What should I do?',
      'answer': 'First, ensure your device is connected to the internet. If the error persists, check that your Flask backend server is running and that your mobile device is connected to the same local network.',
    },
  ];

  // --- Function to show the "Ask a Question" dialog ---
  void _showAskQuestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // We use the separate widget for a cleaner structure
        return const AskQuestionDialog(); 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Frequently Asked Questions", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: _faqList.map((faq) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  // When the user clicks the question, the answer drops down.
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['answer']!,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      // 🛑 FLOATING ACTION BUTTON restored to show the Ask Question dialog 🛑
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAskQuestionDialog(context),
        label: const Text('Ask a Question', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.send, color: Colors.white),
        backgroundColor: const Color(0xFF1A2B47),
      ),
    );
  }
}
// // lib/pages/faq_screen.dart

// import 'package:flutter/material.dart';

// class FaqScreen extends StatelessWidget {
//   const FaqScreen({super.key});

//   // --- FAQ Data Structure (Static Data) ---
//   final List<Map<String, String>> _faqList = const [
//     {
//       'question': 'How do I start a new business application?',
//       'answer': 'Navigate to the Home screen and select "New Application". Fill in all required details across the multi-step form (Taxpayer, Other Information, Business Activity) and submit.',
//     },
//     {
//       'question': 'How do I renew my existing business permit?',
//       'answer': 'Go to the Renewal screen, select your approved business from the list, review and update any changed information (address, contact, activity), submit the renewal form, and then proceed to upload the necessary renewal documents.',
//     },
//     {
//       'question': 'What file types are accepted for document upload?',
//       'answer': 'The system currently accepts files in PDF, JPG, JPEG, and PNG formats. Please ensure documents are clear and legible.',
//     },
//     {
//       'question': 'Why am I seeing "No approved businesses found" in the renewal section?',
//       'answer': 'This usually means your previous applications are still in "Pending Review" or "Draft" status, or the business permit has expired. Only applications marked "Approved" are visible for renewal.',
//     },
//     {
//       'question': 'How can I pay for my permit application?',
//       'answer': 'Once your application is reviewed and approved, you will be directed to the payment gateway. You can pay via Gcash, Maya, or any major credit/debit card.',
//     },
//     {
//       'question': 'How long does the application review process take?',
//       'answer': 'The standard review time is typically 3-5 business days after all necessary documents have been successfully uploaded and verified.',
//     },
//     {
//       'question': 'Where can I check the status of my application?',
//       'answer': 'You can check the status of all applications (New, Renewal, Retirement) on your main Dashboard or Application History screen.',
//     },
//     {
//       'question': 'The app is showing a network error. What should I do?',
//       'answer': 'First, ensure your device is connected to the internet. If the error persists, check that your Flask backend server is running and that your mobile device is connected to the same local network.',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Frequently Asked Questions", style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF1A2B47),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: _faqList.map((faq) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//               child: Card(
//                 elevation: 1,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 child: ExpansionTile(
//                   // When the user clicks the question, the answer drops down.
//                   title: Text(
//                     faq['question']!,
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//                   ),
//                   children: <Widget>[
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                       child: Text(
//                         faq['answer']!,
//                         style: TextStyle(color: Colors.grey[800]),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }