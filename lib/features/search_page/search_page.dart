import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Sanalarni formatlash va parslash uchun
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';
import 'package:tanishuvlar/style/app_style.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedGender;
  String? _selectedCommunicationGoal;
  String? _selectedRegion;

  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredUsers = [];

  final List<String> _genders = ['Erkak', 'Ayol', 'Boshqa'];
  final List<String> _communicationGoals = [
    'Oddiy suhbat',
    'Do\'stlik',
    'Sevgi izlash',
    'Oila qurish'
  ];
  final List<String> _regions = [
    'Qoraqalpog\'iston R.',
    'Andijon',
    'Buxoro',
    'Jizzax',
    'Qashqadaryo',
    'Namangan',
    'Navoiy',
    'Samarqand',
    'Surxondaryo',
    'Sirdaryo',
    'Toshkent sh.',
    'Toshkent vil.',
    'Farg\'ona',
    'Xorazm'
  ];

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
    _searchController.addListener(() {
      _filterUsers();
    });
  }

  Future<void> _loadAllUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('profiles').get();
    setState(() {
      _allUsers = snapshot.docs;
      _filteredUsers = List.from(_allUsers);
    });
  }

  void _filterUsers() {
    String searchText = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredUsers = _allUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName']?.toLowerCase() ?? '';
        final lastName = data['lastName']?.toLowerCase() ?? '';
        final gender = data['gender'] ?? '';
        final communicationGoal = data['communicationGoal'] ?? '';
        final region = data['region'] ?? '';

        bool matchesName =
            firstName.contains(searchText) || lastName.contains(searchText);

        bool matchesGender =
            _selectedGender == null || _selectedGender == gender;

        bool matchesCommunicationGoal = _selectedCommunicationGoal == null ||
            _selectedCommunicationGoal == communicationGoal;

        bool matchesRegion =
            _selectedRegion == null || _selectedRegion == region;

        return matchesName &&
            matchesGender &&
            matchesCommunicationGoal &&
            matchesRegion;
      }).toList();
    });
  }

  // Tug'ilgan sanadan yoshni hisoblash
  int? _calculateAgeFromBirthDate(String birthDateStr) {
    if (birthDateStr.isEmpty) return null;

    try {
      DateTime birthDate = DateFormat('dd.MM.yyyy').parse(birthDateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      print('Tug\'ilgan sanani parslashda xatolik: $e');
      return null;
    }
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('Foydalanuvchilar topilmadi.'));
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final userData = _filteredUsers[index].data() as Map<String, dynamic>;
        final name = userData['firstName'] ?? 'Kiritilmagan';
        final lastName = userData['lastName'] ?? '';
        final gender = userData['gender'] ?? 'Kiritilmagan';
        final region = userData['region'] ?? 'Kiritilmagan';
        final birthDate = userData['birthDate'] ?? 'Kiritilmagan';
        final userEmail =
            _filteredUsers[index].id; // Email hujjat IDsi sifatida

        // Yoshni hisoblash
        int? age = _calculateAgeFromBirthDate(birthDate);

        return Card(
          color: Colors.grey[800],
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(
                gender == 'Erkak'
                    ? 'assets/icons/man.png'
                    : 'assets/icons/woman.png',
              ),
            ),
            title: Text(
              '$name $lastName',
              style: AppStyle.fontStyle.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              'Jins: $gender\nYosh: ${age ?? "Kiritilmagan"}\nHudud: $region',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              _handleUserTap(context, currentUser!.email!, userEmail);
            },
          ),
        );
      },
    );
  }

  Future<void> _handleUserTap(
      BuildContext context, String currentUserEmail, String userEmail) async {
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserEmail)
        .get();

    DocumentSnapshot? existingChat;

    for (var doc in chatSnapshot.docs) {
      var participants = doc['participants'] as List;
      if (participants.contains(userEmail)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: existingChat!.id,
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    } else {
      DocumentReference newChat =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserEmail, userEmail],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: newChat.id,
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedGender = null;
      _selectedCommunicationGoal = null;
      _selectedRegion = null;
      _filteredUsers = List.from(_allUsers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: Text(
          'Foydalanuvchilarni qidirish',
          style: AppStyle.fontStyle.copyWith(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ism/Familiya bo\'yicha qidirish',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[850],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Jins',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[850],
              ),
              value: _selectedGender,
              items: _genders.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGender = newValue;
                  _filterUsers();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Muloqot maqsadi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[850],
              ),
              value: _selectedCommunicationGoal,
              items: _communicationGoals.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCommunicationGoal = newValue;
                  _filterUsers();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Hudud',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[850],
              ),
              value: _selectedRegion,
              items: _regions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRegion = newValue;
                  _filterUsers();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildUserList(),
            ),
          ],
        ),
      ),
    );
  }
}
