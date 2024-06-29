import 'package:flutter/material.dart';
import 'contacts_page.dart';
import 'gallary_page.dart';
import 'setting_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookshelf',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tabbed App'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
              Tab(icon: Icon(Icons.photo_album), text: 'Gallery'),
              Tab(icon: Icon(Icons.book), text: "Today's book"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContactsPage(),
            GalleryPage(),
            TodaysBookPage(),
          ],
        ),
      ),
    );
  }
}
