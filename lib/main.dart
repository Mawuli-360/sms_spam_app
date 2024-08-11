import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

void main() => runApp(const SpamDetectorApp());

class SpamDetectorApp extends StatelessWidget {
  const SpamDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Spam Detector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _contacts = [];
  List<SmsMessage> _messages = [];
  final Map<String, List<SmsMessage>> _categorizedMessages = {
    'Ham': [],
    'Spam': [],
    'Undecidable': [],
  };
  bool _isLoading = true;


  final List<String> _spamKeywords = [
  'urgent', 'winner', 'cash prize', 'lottery', 'click here',
  'limited time offer', 'act now', 'congratulations', 'free gift',
  'investment opportunity', 'earn money fast', 'get rich quick',
  'exclusive deal', 'best rates', 'viagra', 'cialis', 'enlargement',
  'lose weight', 'miracle cure', 'risk-free', '100% guaranteed'
];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

Future<void> _initializeData() async {
  setState(() {
    _isLoading = true;
  });

  bool hasPermissions = await _requestPermissions();
  if (hasPermissions) {
    await _loadContactsAndMessages();
  } else {
    print("Permissions not granted");
  }

  setState(() {
    _isLoading = false;
  });
}

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
      Permission.sms,
    ].request();

    return statuses[Permission.contacts]!.isGranted &&
        statuses[Permission.sms]!.isGranted;
  }

  Future<void> _loadContactsAndMessages() async {
    try {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts.toList();
      });

      final SmsQuery query = SmsQuery();
      List<SmsMessage> messages = await query.getAllSms;
      setState(() {
        _messages = messages;
        _categorizeMessages();
      });
    } catch (e) {
      print("Error loading contacts or messages: $e");
    }
  }

  void _categorizeMessages() {
    for (var message in _messages) {
      try {
        if (_isSpam(message)) {
          _categorizedMessages['Spam']!.add(message);
        } else if (_isFromContact(message)) {
          _categorizedMessages['Ham']!.add(message);
        } else {
          _categorizedMessages['Undecidable']!.add(message);
        }
      } catch (e) {
        print('Error categorizing message: $e');
        _categorizedMessages['Undecidable']!.add(message);
      }
    }
  }

  bool _isFromContact(SmsMessage message) {
    return _contacts.any((contact) =>
        contact.phones?.any((phone) => phone.value == message.address) == true);
  }

bool _isSpam(SmsMessage message) {
  if (message.body == null) return false;
  
  String lowerCaseBody = message.body!.toLowerCase();
  
  for (String keyword in _spamKeywords) {
    if (lowerCaseBody.contains(keyword.toLowerCase())) {
      return true;
    }
  }
  
  return false;
}


  bool _isHam(SmsMessage message) {
    return _isFromContact(message);
  }

  String _getContactName(String? phoneNumber) {
    if (phoneNumber == null) return 'Unknown';
    for (var contact in _contacts) {
      for (var phone in contact.phones ?? []) {
        if (phone.value != null &&
            phone.value!.replaceAll(RegExp(r'\D'), '') ==
                phoneNumber.replaceAll(RegExp(r'\D'), '')) {
          return contact.displayName ?? 'Unknown';
        }
      }
    }
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Spam Detector'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ham'),
            Tab(text: 'Spam'),
            Tab(text: 'Undecidable'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMessageList('Ham'),
                _buildMessageList('Spam'),
                _buildMessageList('Undecidable'),
              ],
            ),
    );
  }

  Widget _buildMessageList(String category) {
    return ListView.builder(
      itemCount: _categorizedMessages[category]!.length,
      itemBuilder: (context, index) {
        SmsMessage message = _categorizedMessages[category]![index];
        String contactName = _getContactName(message.address);
        return ListTile(
          title: Text('$contactName (${message.address ?? 'Unknown'})'),
          subtitle: Text(message.body ?? ''),
          onTap: () {
            if (_isValidPhoneNumber(message.address)) {
              _showReplyDialog(message);
            }
          },
        );
      },
    );
  }

  bool _isValidPhoneNumber(String? address) {
    if (address == null) return false;
    return RegExp(r'^\+?\d{10,}$').hasMatch(address);
  }

  void _showReplyDialog(SmsMessage message) {
    String contactName = _getContactName(message.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to $contactName (${message.address})'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Enter your reply'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Send'),
            onPressed: () {
              // Implement send functionality
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
