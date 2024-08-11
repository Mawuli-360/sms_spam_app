// class SMSMessage {
//   final String address;
//   final String body;
//   final DateTime date;
//   String contactName;

//   SMSMessage({
//     required this.address,
//     required this.body,
//     required this.date,
//     this.contactName = '',
//   });

//   factory SMSMessage.fromSmsMessage(message) {
//     return SMSMessage(
//       address: message.address ?? '',
//       body: message.body ?? '',
//       date: message.date ?? DateTime.now(),
//     );
//   }

//   factory SMSMessage.fromTelephonyMessage(message) {
//     return SMSMessage(
//       address: message.address ?? '',
//       body: message.body ?? '',
//       date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
//     );
//   }
// }
