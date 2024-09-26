import 'package:flutter/material.dart';
import 'package:tanishuvlar/features/account_page/profile.dart';
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';
import 'package:tanishuvlar/features/chat_page/chat_page.dart';
import 'package:tanishuvlar/features/home_page/home_page.dart';
import 'package:tanishuvlar/features/search_page/search_page.dart';

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Asosiy'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Qidiruv'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
