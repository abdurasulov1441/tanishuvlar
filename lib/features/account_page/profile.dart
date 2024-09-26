import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tanishuvlar/style/app_style.dart';

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
    await _auth.signOut();
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
      print('Profilni yuklashda xatolik: $e');
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
        print('Profilni saqlashda xatolik: $e');
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

  final _phoneNumberFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      if (newValue.text.isEmpty) {
        return newValue.copyWith(text: '+998 ');
      }
      String digits = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');
      if (!digits.startsWith('+998')) {
        digits = '+998';
      }
      if (digits.length > 13) {
        digits = digits.substring(0, 13);
      }
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

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        leading: IconButton(
            onPressed: () {
              signOut();
            },
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            )),
        title: Text(
          'Profil',
          style: AppStyle.fontStyle.copyWith(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Profilingizni to\'ldiring',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_firstNameController, 'Ism', false),
                          _buildTextField(
                              _lastNameController, 'Familiya', false),
                          _buildDatePickerField(
                              _birthDateController, 'Tug\'ilgan kun', context),
                          _buildDropdownButton(
                            'Jins',
                            _selectedGender,
                            _genders,
                            (newValue) {
                              setState(() {
                                _selectedGender = newValue!;
                              });
                            },
                          ),
                          _buildDropdownButton(
                            'Hudud',
                            region,
                            _regions,
                            (newValue) {
                              setState(() {
                                region = newValue!;
                              });
                            },
                          ),
                          _buildTextField(_phoneController, 'Telefon', true),
                          _buildDropdownButton(
                            'Muloqot maqsadi',
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Button color
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Profilni saqlash'),
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
                        _buildProfileField('Ism', firstName ?? 'Kiritilmagan'),
                        _buildProfileField(
                            'Familiya', lastName ?? 'Kiritilmagan'),
                        _buildProfileField(
                            'Tug\'ilgan kun', birthDate ?? 'Kiritilmagan'),
                        _buildProfileField(
                            'Jins', _selectedGender ?? 'Kiritilmagan'),
                        _buildProfileField('Hudud', region ?? 'Kiritilmagan'),
                        _buildProfileField('Telefon', phone ?? 'Kiritilmagan'),
                        _buildProfileField('Muloqot maqsadi',
                            _selectedCommunicationGoal ?? 'Kiritilmagan'),
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
              color: Colors.grey[850], // Darker background for contrast
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.isEmpty ? 'Kiritilmagan' : value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
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
            return 'Iltimos, maydonni to\'ldiring';
          }
          if (isPhoneNumber &&
              !RegExp(r'^\+998 \(\d{2}\) \d{3} \d{2} \d{2}$').hasMatch(value)) {
            return 'Telefon raqam formati noto\'g\'ri';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white), // Label color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[800], // Input background color
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
                return 'Iltimos, sanani tanlang';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.white), // Label color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              filled: true,
              fillColor: Colors.grey[800], // Input background color
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
            return 'Iltimos, qiymatni tanlang';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white), // Label color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[800], // Input background color
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white)), // Dropdown item color
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
