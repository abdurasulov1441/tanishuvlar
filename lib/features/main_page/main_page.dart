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
      HomePage(onUserSelected: _navigateToChat),
      const SearchPage(),
      const ChatPage(),
      DisplayProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToChat(String userId, String userName) {
    setState(() {
      _selectedIndex = 2; // Переключаемся на вкладку чата
    });

    // Здесь можно передать данные о пользователе в чате
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatDetailPage(userId: userId, chatUserName: userName),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чат'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Профиль'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
