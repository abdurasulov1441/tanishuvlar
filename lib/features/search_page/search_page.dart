import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Контроллер для поиска по имени и фамилии
  final TextEditingController _searchController = TextEditingController();

  // Пол, цель общения, область
  String? _selectedGender;
  String? _selectedCommunicationGoal;
  String? _selectedRegion;

  // Список пользователей
  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredUsers = [];

  // Опции для выпадающих списков
  final List<String> _genders = ['Мужчина', 'Женщина', 'Другой'];
  final List<String> _communicationGoals = [
    'Просто так',
    'Дружба',
    'Поиск любви',
    'Завести семью'
  ];
  final List<String> _regions = [
    'Ташкент',
    'Самарканд',
    'Фергана',
    'Андижан',
    'Другой'
  ];

  // Получение текущего пользователя
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    // Загружаем всех пользователей из Firestore при инициализации
    _loadAllUsers();

    // Обновляем результаты при изменении текста поиска
    _searchController.addListener(() {
      _filterUsers();
    });
  }

  // Метод для загрузки всех пользователей
  Future<void> _loadAllUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('profiles').get();
    setState(() {
      _allUsers = snapshot.docs; // Сохраняем всех пользователей
      _filteredUsers = List.from(_allUsers); // Изначально показываем всех
    });
  }

  // Метод для фильтрации пользователей на клиенте
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

        // Фильтрация по имени или фамилии
        bool matchesName =
            firstName.contains(searchText) || lastName.contains(searchText);

        // Фильтрация по полу
        bool matchesGender =
            _selectedGender == null || _selectedGender == gender;

        // Фильтрация по цели общения
        bool matchesCommunicationGoal = _selectedCommunicationGoal == null ||
            _selectedCommunicationGoal == communicationGoal;

        // Фильтрация по области проживания
        bool matchesRegion =
            _selectedRegion == null || _selectedRegion == region;

        // Возвращаем true, если все условия выполняются
        return matchesName &&
            matchesGender &&
            matchesCommunicationGoal &&
            matchesRegion;
      }).toList();
    });
  }

  // Метод для отображения результатов
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
        final userEmail = _filteredUsers[index].id; // email as document ID

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage(
              gender == 'Мужчина'
                  ? 'assets/icons/man.png'
                  : 'assets/icons/woman.png',
            ),
          ),
          title: Text('$name $lastName'),
          subtitle: Text('Пол: $gender\nОбласть: $region'),
          onTap: () {
            _handleUserTap(
                context, currentUser!.email!, userEmail); // Переход в чат
          },
        );
      },
    );
  }

  // Метод для обработки нажатия на пользователя
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

  // Метод для очистки всех полей
  void _clearFilters() {
    setState(() {
      _searchController.clear(); // Очистка текстового поля
      _selectedGender = null; // Сброс выбора пола
      _selectedCommunicationGoal = null; // Сброс выбора цели общения
      _selectedRegion = null; // Сброс региона
      _filteredUsers = List.from(_allUsers); // Показ всех пользователей
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
            onPressed: _clearFilters, // Кнопка для очистки всех фильтров
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
                  _filterUsers(); // Фильтрация при изменении
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
                  _filterUsers(); // Фильтрация при изменении
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
                  _filterUsers(); // Фильтрация при изменении
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
