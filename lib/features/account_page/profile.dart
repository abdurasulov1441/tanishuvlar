import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DisplayProfilePage extends StatefulWidget {
  const DisplayProfilePage({super.key});

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

          region =
              _regions.contains(userDoc['region']) ? userDoc['region'] : null;

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
          'region': region,
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

  // Phone number formatter to format phone numbers like +998 (XX) XXX XX XX
  final _phoneNumberFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      if (newValue.text.isEmpty) {
        return newValue.copyWith(text: '+998 ');
      }

      // Remove all non-digit characters, except '+' at the beginning
      String digits = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');

      // Ensure it starts with +998
      if (!digits.startsWith('+998')) {
        digits = '+998';
      }

      // Limiting the input to match the format
      if (digits.length > 13) {
        digits = digits.substring(0, 13); // Limit to the +998 XXX XX XX format
      }

      // Format the number
      String formatted = digits;

      if (digits.length > 4) {
        formatted = '+998 (${digits.substring(4, min(6, digits.length))}';
      }
      if (digits.length > 6) {
        formatted += ') ${digits.substring(6, min(9, digits.length))}';
      }
      if (digits.length > 9) {
        formatted += ' ${digits.substring(9, min(11, digits.length))}';
      }
      if (digits.length > 11) {
        formatted += ' ${digits.substring(11)}';
      }

      // Ensure the selection index stays after the new text
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              signOut();
            },
            icon: const Icon(Icons.exit_to_app)),
        title: const Text('Профиль'),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                  _firstNameController.text = firstName ?? '';
                  _lastNameController.text = lastName ?? '';
                  _birthDateController.text = birthDate ?? '';
                  _phoneController.text = phone ?? '';
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEditing
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Заполните профиль',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_firstNameController, 'Имя', false),
                          _buildTextField(
                              _lastNameController, 'Фамилия', false),
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
                          _buildDropdownButton(
                            'Область',
                            region,
                            _regions,
                            (newValue) {
                              setState(() {
                                region = newValue!;
                              });
                            },
                          ),
                          _buildTextField(_phoneController, 'Телефон', true),
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
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveUserProfile,
                            child: const Text('Сохранить профиль'),
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
                        const SizedBox(height: 20),
                        const Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                AssetImage('assets/images/user.png'),
                          ),
                        ),
                        const SizedBox(height: 20),
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
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.isEmpty ? 'Не указано' : value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, bool isPhoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhoneNumber ? [_phoneNumberFormatter] : [],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Пожалуйста, заполните поле';
          }
          if (isPhoneNumber &&
              !RegExp(r'^\+998 \(\d{2}\) \d{3} \d{2} \d{2}$').hasMatch(value)) {
            return 'Неверный формат номера телефона';
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
