class CustomSmsMessage {
  final String? address;
  final String? body;
  final DateTime date;

  CustomSmsMessage({
    this.address,
    this.body,
    required this.date,
  });
}