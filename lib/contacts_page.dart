import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'second_contacts.dart';

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
    final data = json.decode(response);
    setState(() {
      contacts = List<Contact>.from(data.map((item) => Contact.fromJson(item)));
      contacts.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizeX = MediaQuery.of(context).size.width;
    final sizeY = MediaQuery.of(context).size.height;
    return MaterialApp(
        title: 'ListView',
        home: Scaffold(
          appBar: AppBar(title: const Text('Contacts')),
          body: contacts.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(contacts[index].name),
                        subtitle: Text(contacts[index].phone),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[400],
                          child: Icon(int.parse(contacts[index].icon) == 1
                              ? Icons.person
                              : Icons.question_mark),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SecondContacts(
                                        name: contacts[index].name,
                                        phone: contacts[index].phone,
                                      )),
                            ));
                  },
                ),
        ));
  }
}

class Contact {
  final String name;
  final String phone;
  final String icon;

  Contact({required this.name, required this.phone, required this.icon});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      phone: json['phone'],
      icon: json['icon'],
    );
  }
}
