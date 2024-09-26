import 'package:flutter/material.dart';
import 'package:tanishuvlar/features/account_page/profile.dart';
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';
import 'package:tanishuvlar/features/chat_page/chat_page.dart';
import 'package:tanishuvlar/features/home_page/home_page.dart';
import 'package:tanishuvlar/features/search_page/search_page.dart';
import 'package:tanishuvlar/style/app_style.dart'; // Подключаем стиль

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const SearchPage(),
      const ChatPage(),
      const DisplayProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Funksiyani to'g'ri chatga o'tish uchun tuzatish
  void _navigateToChat(String chatId, String userEmail) {
    setState(() {
      _selectedIndex = 2; // Chat bo'limiga o'tish
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chatId: chatId, // Chat IDni o'tkazish
          userId: userEmail, // Suhbatdoshning emaili
          chatUserName: userEmail, // Suhbatdoshning ismi (email)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F), // Asosiy fon
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black, // Qora fon qo'yamiz
        type: BottomNavigationBarType.fixed, // Barni to'g'ri ishlash uchun
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home, color: Colors.white), label: 'Asosiy'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search, color: Colors.white), label: 'Qidiruv'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat, color: Colors.white), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle, color: Colors.white),
              label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50), // Tanlangan element rangi
        unselectedItemColor: Colors.grey[600], // Tanlanmagan elementlar rangi
        onTap: _onItemTapped,
        selectedLabelStyle:
            AppStyle.fontStyle.copyWith(color: const Color(0xFF4CAF50)),
        unselectedLabelStyle:
            AppStyle.fontStyle.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}
