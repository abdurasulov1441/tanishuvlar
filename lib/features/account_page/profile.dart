import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DisplayProfilePage extends StatefulWidget {
  @override
  _DisplayProfilePageState createState() => _DisplayProfilePageState();
}

class _DisplayProfilePageState extends State<DisplayProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  String? firstName;
  String? lastName;
  String? birthDate;
  String? gender;
  String? region;
  String? phone;
  String? communicationGoal;

  bool isLoading = true; // Индикатор загрузки
  bool profileExists = false; // Указывает, существует ли профиль

  // Контроллеры для формы
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Пол и цель общения как значения для выпадающих списков
  String? _selectedGender;
  String? _selectedCommunicationGoal;

  // Список опций для пола
  final List<String> _genders = ['Мужчина', 'Женщина', 'Другой'];

  // Список опций для цели общения
  final List<String> _communicationGoals = [
    'Просто так',
    'Дружба',
    'Поиск любви',
    'Завести семью'
  ];

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _loadUserProfile();
    }
  }

  // Метод для загрузки данных профиля пользователя из Firestore
  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('profiles').doc(user!.email).get();

      if (userDoc.exists) {
        // Если документ существует, загружаем данные
        setState(() {
          firstName = userDoc['firstName'] ?? ''; // Если null, то пустая строка
          lastName = userDoc['lastName'] ?? '';
          birthDate = userDoc['birthDate'] ?? '';
          _selectedGender = userDoc['gender'] ?? '';
          region = userDoc['region'] ?? '';
          phone = userDoc['phone'] ?? '';
          _selectedCommunicationGoal = userDoc['communicationGoal'] ?? '';
          profileExists = true; // Профиль существует
          isLoading = false;
        });
      } else {
        // Если документа нет, предложим заполнить профиль
        setState(() {
          profileExists = false;
          isLoading = false;
        });
      }
    } catch (e) {
      // Обработка ошибок
      print('Ошибка загрузки профиля: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Метод для сохранения данных профиля в Firestore
  Future<void> _saveUserProfile() async {
    try {
      await _firestore.collection('profiles').doc(user!.email).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'birthDate': _birthDateController.text,
        'gender': _selectedGender,
        'region': _regionController.text,
        'phone': _phoneController.text,
        'communicationGoal': _selectedCommunicationGoal,
      });
      setState(() {
        profileExists = true; // Профиль создан
      });
      _loadUserProfile(); // Перезагрузим данные
    } catch (e) {
      print('Ошибка сохранения профиля: $e');
    }
  }

  // Метод для выбора даты рождения
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.day}.${picked.month}.${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Индикатор загрузки
          : profileExists
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        // Аватар пользователя
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(
                                'assets/images/user.png'), // Путь к изображению
                          ),
                        ),
                        SizedBox(height: 20),
                        // Поля профиля
                        _buildProfileField('Имя', firstName ?? 'Не указано'),
                        _buildProfileField('Фамилия', lastName ?? 'Не указано'),
                        _buildProfileField(
                            'Дата рождения', birthDate ?? 'Не указано'),
                        _buildProfileField(
                            'Пол', _selectedGender ?? 'Не указано'),
                        _buildProfileField('Область', region ?? 'Не указано'),
                        _buildProfileField('Телефон', phone ?? 'Не указано'),
                        _buildProfileField('Цель общения',
                            _selectedCommunicationGoal ?? 'Не указано'),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  // Добавляем скролл для формы
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'Заполните профиль',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(_firstNameController, 'Имя'),
                        _buildTextField(_lastNameController, 'Фамилия'),
                        // Выбор даты рождения
                        _buildDatePickerField(
                            _birthDateController, 'Дата рождения', context),
                        
                        _buildDropdownButton(
                          'Пол',
                          _selectedGender,
                          _genders,
                          (newValue) {
                            setState(() {
                              _selectedGender = newValue!;
                            });
                          },
                        ),
                        _buildTextField(_regionController, 'Область'),
                        _buildTextField(_phoneController, 'Телефон'),
                        // Dropdown для выбора цели общения
                        _buildDropdownButton(
                          'Цель общения',
                          _selectedCommunicationGoal,
                          _communicationGoals,
                          (newValue) {
                            setState(() {
                              _selectedCommunicationGoal = newValue!;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveUserProfile,
                          child: Text('Сохранить профиль'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Метод для создания виджета отображения данных профиля
  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.isEmpty
                  ? 'Не указано'
                  : value, 
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildTextField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(TextEditingController controller,
      String labelText, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildDropdownButton(String labelText, String? selectedValue,
      List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
