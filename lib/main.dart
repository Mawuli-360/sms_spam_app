import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:sms_spam_app/sms_receiver.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const SpamDetectorApp());

class SpamDetectorApp extends StatelessWidget {
  const SpamDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Spam Detector',
      debugShowCheckedModeBanner: false,
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
  late SmsReceiver _smsReceiver;
  late Interpreter _interpreter;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadModel();
    _initializeData();
    _initializeSmsReceiver();

    // Listener for scroll events to toggle visibility of FloatingActionButton
    _scrollController.addListener(() {
      setState(() {
        // The FAB should appear if the scroll offset is greater than 100
        _isFabVisible = _scrollController.offset > 100;
      });
    });
  }

  void _initializeSmsReceiver() {
    _smsReceiver = SmsReceiver(
      onMessageReceived: (var message) {
        _handleNewMessage(message as SmsMessage);
      },
    );
  }

  void _restartApp() {
    setState(() {
      _isLoading = true;
    });

    // Reset all data
    _contacts = [];
    _messages = [];
    _categorizedMessages.forEach((key, value) => value.clear());

    // Reinitialize everything
    _loadModel();
    _initializeData();
    _initializeSmsReceiver();
  }

  Future<void> _handleNewMessage(SmsMessage message) async {
    setState(() {
      _messages.add(message);
    });

    try {
      if (await _isSpam(message)) {
        setState(() {
          _categorizedMessages['Spam']!.add(message);
          _categorizedMessages['Spam']!
              .sort((a, b) => b.date!.compareTo(a.date!));
        });
      } else {
        setState(() {
          _categorizedMessages['Ham']!.add(message);
          _categorizedMessages['Ham']!
              .sort((a, b) => b.date!.compareTo(a.date!));
        });
      }
    } catch (e) {
      print('Error categorizing new message: $e');
      setState(() {
        _categorizedMessages['Undecidable']!.add(message);
        _categorizedMessages['Undecidable']!
            .sort((a, b) => b.date!.compareTo(a.date!));
      });
    }
    setState(() {});
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

  List<double> _preprocessMessage(String message, bool isFromContact) {
    List<double> vector = List.filled(100, 0.0);

    List<String> words = message.toLowerCase().split(' ');
    for (int i = 0; i < words.length && i < 99; i++) {
      vector[i] = words[i]
          .codeUnits
          .reduce((value, element) => value + element)
          .toDouble();
    }

    vector[99] = isFromContact ? 1.0 : 0.0;

    return vector;
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
      Permission.sms,
    ].request();

    return statuses[Permission.contacts]!.isGranted &&
        statuses[Permission.sms]!.isGranted;
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/spam_detection_model.tflite');
      print('Model loaded successfully');
      print('Input shape: ${_interpreter.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter.getOutputTensor(0).shape}');
    } catch (e) {
      print('Failed to load model: $e');
    }
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

  Future<void> _categorizeMessages() async {
    for (var message in _messages) {
      try {
        if (await _isSpam(message)) {
          _categorizedMessages['Spam']!.add(message);
        } else {
          _categorizedMessages['Ham']!.add(message);
        }
      } catch (e) {
        print('Error categorizing message: $e');
        _categorizedMessages['Undecidable']!.add(message);
      }
    }

    _categorizedMessages.forEach((key, value) {
      value.sort((a, b) => b.date!.compareTo(a.date!));
    });

    setState(() {});
  }

  bool _isFromContact(SmsMessage message) {
    return _contacts.any((contact) =>
        contact.phones?.any((phone) => phone.value == message.address) == true);
  }

  Future<bool> _isSpam(SmsMessage message) async {
    if (message.body == null) return false;

    List<double> input =
        _preprocessMessage(message.body!, _isFromContact(message));

    var output = List<double>.filled(1, 0).reshape([1, 1]);

    try {
      _interpreter.run(input.reshape([1, input.length]), output);
    } catch (e) {
      print('Model inference failed: $e');
      return false;
    }

    return output[0][0] > 0.5;
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
            Tab(text: 'Not Spam'),
            Tab(text: 'Spam'),
            Tab(text: 'Cannot Decide'),
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
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildMessageList(String category) {
    return LiquidPullToRefresh(
      onRefresh: () async {
        _restartApp();
      },
      showChildOpacityTransition: false,
      child: ListView.builder(
        controller: _scrollController, // Attach the scroll controller
        itemCount: _categorizedMessages[category]!.length,
        itemBuilder: (context, index) {
          SmsMessage message = _categorizedMessages[category]![index];
          String contactName = _getContactName(message.address);
          bool isFromContact = _isFromContact(message);
          return ListTile(
            title: Text(
                '$contactName (${message.address ?? 'Unknown'})${isFromContact ? ' (Contact)' : ''}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.body ?? ''),
                const SizedBox(height: 4),
                Text(
                  '${message.date?.toLocal()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              if (_isValidPhoneNumber(message.address)) {
                _showReplyDialog(message);
              }
            },
          );
        },
      ),
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
        title: Text('Reply to $contactName'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () async {
              if (message.address != null) {
                final Uri smsLaunchUri = Uri(
                  scheme: 'sms',
                  path: message.address,
                );
                try {
                  await launchUrl(smsLaunchUri);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('SMS app opened successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to open SMS app: $e')),
                  );
                }
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    _scrollController.dispose(); // Dispose the scroll controller
    _tabController.dispose();
    super.dispose();
  }
}
