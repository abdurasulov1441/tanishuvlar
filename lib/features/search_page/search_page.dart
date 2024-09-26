import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // To format and parse dates
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';

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

  final List<String> _genders = ['Мужчина', 'Женщина', 'Другой'];
  final List<String> _communicationGoals = [
    'Просто так',
    'Дружба',
    'Поиск любви',
    'Завести семью'
  ];
  final List<String> _regions = [
    'Каракалпакстан Р',
    'Андижан',
    'Бухара',
    'Джизах',
    'Кашкадарья',
    'Наманган',
    'Наваи',
    'Самарканд',
    'Сурхандарья',
    'Сирдарья',
    'город Ташкент',
    'Ташкент обл',
    'Фергана',
    'Хорезм'
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

        // Fetching birthDate
        final birthDateStr = data['birthDate'] ?? '';
        int? age = _calculateAgeFromBirthDate(birthDateStr);

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

  // Method to calculate age from birthDate
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
      print('Error parsing birth date: $e');
      return null;
    }
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('Пользователи не найдены.'));
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final userData = _filteredUsers[index].data() as Map<String, dynamic>;
        final name = userData['firstName'] ?? 'Не указано';
        final lastName = userData['lastName'] ?? '';
        final gender = userData['gender'] ?? 'Не указано';
        final region = userData['region'] ?? 'Не указано';
        final birthDate = userData['birthDate'] ?? 'Не указано';
        final userEmail = _filteredUsers[index].id; // Email as document ID

        // Calculate age
        int? age = _calculateAgeFromBirthDate(birthDate);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage(
              gender == 'Мужчина'
                  ? 'assets/icons/man.png'
                  : 'assets/icons/woman.png',
            ),
          ),
          title: Text('$name $lastName'),
          subtitle: Text(
              'Пол: $gender\nВозраст: ${age ?? "Не указано"}\nОбласть: $region'),
          onTap: () {
            _handleUserTap(context, currentUser!.email!, userEmail);
          },
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
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
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
              decoration: const InputDecoration(
                labelText: 'Поиск по имени/фамилии',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Пол',
                border: OutlineInputBorder(),
              ),
              value: _selectedGender,
              items: _genders.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              decoration: const InputDecoration(
                labelText: 'Цель общения',
                border: OutlineInputBorder(),
              ),
              value: _selectedCommunicationGoal,
              items: _communicationGoals.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              decoration: const InputDecoration(
                labelText: 'Область проживания',
                border: OutlineInputBorder(),
              ),
              value: _selectedRegion,
              items: _regions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
