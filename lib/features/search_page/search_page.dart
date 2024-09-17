import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты и вычисления возраста

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

  // Диапазон возраста
  RangeValues _ageRange = const RangeValues(14, 60); // Возраст от 14 до 60 лет

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

  // Метод для поиска пользователей
  Stream<QuerySnapshot> _searchUsers() {
    Query query = FirebaseFirestore.instance.collection('profiles');

    // Исключаем текущего пользователя
    if (currentUser != null) {
      query =
          query.where(FieldPath.documentId, isNotEqualTo: currentUser!.email);
    }

    // Поиск по имени и фамилии
    if (_searchController.text.isNotEmpty) {
      query = query.where('firstName',
          isGreaterThanOrEqualTo: _searchController.text);
    }

    // Фильтр по полу
    if (_selectedGender != null && _selectedGender!.isNotEmpty) {
      query = query.where('gender', isEqualTo: _selectedGender);
    }

    // Фильтр по цели общения
    if (_selectedCommunicationGoal != null &&
        _selectedCommunicationGoal!.isNotEmpty) {
      query = query.where('communicationGoal',
          isEqualTo: _selectedCommunicationGoal);
    }

    // Фильтр по области
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      query = query.where('region', isEqualTo: _selectedRegion);
    }

    // Фильтр по возрасту
    int currentYear = DateTime.now().year;
    int minYear = currentYear - _ageRange.end.toInt(); // Старший возраст
    int maxYear = currentYear - _ageRange.start.toInt(); // Младший возраст

    // Фильтруем пользователей по возрасту, предполагаем, что birthDate хранится как строка в формате "dd.MM.yyyy"
    query = query.where('birthDate',
        isGreaterThanOrEqualTo:
            DateFormat('d.M.yyyy').format(DateTime(minYear, 1, 1)));
    query = query.where('birthDate',
        isLessThanOrEqualTo:
            DateFormat('d.M.yyyy').format(DateTime(maxYear, 12, 31)));

    return query.snapshots();
  }

  @override
  void initState() {
    super.initState();

    // Обновляем результаты при вводе текста
    _searchController.addListener(() {
      setState(() {}); // Обновляем интерфейс при изменении текста поиска
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поле для поиска по имени и фамилии
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск по имени/фамилии',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Фильтр по полу
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
                });
              },
            ),
            const SizedBox(height: 16),

            // Фильтр по цели общения
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
                });
              },
            ),
            const SizedBox(height: 16),

            // Фильтр по области
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
                });
              },
            ),
            const SizedBox(height: 16),

            // Слайдер для диапазона возраста
            Text(
                'Возраст: ${_ageRange.start.round()} - ${_ageRange.end.round()} лет'),
            RangeSlider(
              values: _ageRange,
              min: 14, // Начало с 14 лет
              max: 100,
              divisions: 86,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const SizedBox(height: 16),

            // Результаты поиска
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _searchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Пользователи не найдены.'));
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final name = userData['firstName'] ?? 'Не указано';
                      final lastName = userData['lastName'] ?? '';
                      final birthDate = userData['birthDate'] ?? 'Не указано';
                      final gender = userData['gender'] ?? 'Не указано';
                      final region = userData['region'] ?? 'Не указано';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('$name $lastName'),
                        subtitle: Text(
                            'Дата рождения: $birthDate\nПол: $gender\nОбласть: $region'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
