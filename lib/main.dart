import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabbed App',
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
          title: Text('Tabbed App'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
              Tab(icon: Icon(Icons.photo_album), text: 'Gallery'),
              Tab(icon: Icon(Icons.category), text: 'Custom'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContactsPage(),
            GalleryPage(),
            CustomPage(),
          ],
        ),
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final String response = await rootBundle.loadString('assets/contacts.json');
    final data = await json.decode(response);
    setState(() {
      contacts = List<Contact>.from(data.map((item) => Contact.fromJson(item)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(contacts[index].name),
          subtitle: Text(contacts[index].phone),
        );
      },
    );
  }
}

class Contact {
  final String name;
  final String phone;

  Contact({required this.name, required this.phone});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      phone: json['phone'],
    );
  }
}

class GalleryPage extends StatelessWidget {
  final List<String> imageUrls = [];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: imageUrls[index],
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      },
    );
  }
}

class CustomPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Custom Page'),
    );
  }
}
