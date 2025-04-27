
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? selectedValue;
  final List<String> options = [
    'restaurant1',
    'restaurant2',
    'restaurant3',
    'bar1',
    'bar2',
  ];

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _saveSelectedPlace() async {
    if (selectedValue != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('place_id', selectedValue!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected place saved: $selectedValue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('Welcome ${user?.email ?? "User"}!'),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedValue,
              hint: const Text('Select a place'),
              isExpanded: true,
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedValue != null ? _saveSelectedPlace : null,
              child: const Text('Save Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
