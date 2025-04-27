
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${user?.email ?? "User"}!'),
            const SizedBox(height: 20),
            const Text('You have successfully logged in.'),
            const SizedBox(height: 20),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return options;
                }
                return options.where((String option) {
                  return option.toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                setState(() {
                  selectedValue = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Select a venue',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                );
              },
            ),
            if (selectedValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text('Selected venue: $selectedValue'),
              ),
          ],
        ),
      ),
    );
  }
}
