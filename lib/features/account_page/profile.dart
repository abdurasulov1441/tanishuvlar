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

  Future<void> signOut() async {
    final navigator = Navigator.of(context);

    await FirebaseAuth.instance.signOut();

    navigator.pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
  }

  User? user;
  String? firstName;
  String? lastName;
  String? birthDate;
  String? gender;
  String? region;
  String? phone;
  String? communicationGoal;

  bool isLoading = true;
  bool profileExists = false;
  bool isEditing = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  String? _selectedCommunicationGoal;

  final List<String> _genders = ['Мужчина', 'Женщина', 'Другой'];
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

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('profiles').doc(user!.email).get();

      if (userDoc.exists) {
        setState(() {
          firstName = userDoc['firstName'] ?? '';
          lastName = userDoc['lastName'] ?? '';
          birthDate = userDoc['birthDate'] ?? '';
          _selectedGender = userDoc['gender'] ?? '';
          region = userDoc['region'] ?? '';
          phone = userDoc['phone'] ?? '';
          _selectedCommunicationGoal = userDoc['communicationGoal'] ?? '';
          profileExists = true;
          isLoading = false;
        });
      } else {
        setState(() {
          profileExists = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate()) {
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
          profileExists = true;
          isEditing = false;
        });
        _loadUserProfile();
      } catch (e) {
        print('Ошибка сохранения профиля: $e');
      }
    }
  }

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
        leading: IconButton(
            onPressed: () {
              signOut();
            },
            icon: Icon(Icons.exit_to_app)),
        title: Text('Профиль'),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                  _firstNameController.text = firstName ?? '';
                  _lastNameController.text = lastName ?? '';
                  _birthDateController.text = birthDate ?? '';
                  _regionController.text = region ?? '';
                  _phoneController.text = phone ?? '';
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isEditing
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
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
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                AssetImage('assets/images/user.png'),
                          ),
                        ),
                        SizedBox(height: 20),
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
                ),
    );
  }

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
              value.isEmpty ? 'Не указано' : value,
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
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Пожалуйста, заполните поле';
          }
          return null;
        },
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
          child: TextFormField(
            controller: controller,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, выберите дату';
              }
              return null;
            },
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Пожалуйста, выберите значение';
          }
          return null;
        },
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
