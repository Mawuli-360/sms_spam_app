// import 'package:flutter/material.dart';
// import 'package:sms_spam_app/models/sms_message_model.dart';

// class MessageDetailScreen extends StatelessWidget {
//   final SMSMessage message;
//   final bool canReply;

//   const MessageDetailScreen(
//       {super.key, required this.message, required this.canReply});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(message.address),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(message.body),
//             ),
//           ),
//           if (canReply)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Type your reply...',
//                   suffixIcon: IconButton(
//                     icon: const Icon(Icons.send),
//                     onPressed: () {
//                       // Implement send functionality
//                     },
//                   ),
//                 ),
//               ),
//             )
//           else
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text('Cannot reply to this message',
//                   style: TextStyle(color: Colors.red)),
//             ),
//         ],
//       ),
//     );
//   }
// }
