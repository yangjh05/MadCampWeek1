import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'second_contacts.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

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
                        subtitle: Text(contacts[index].book),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[400],
                          backgroundImage: AssetImage(contacts[index].image),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SecondContacts(
                                        number: contacts[index].number,
                                        name: contacts[index].name,
                                        book: contacts[index].book,
                                        image: contacts[index].image,
                                        birth: contacts[index].birth,
                                        nation: contacts[index].nation,
                                        education: contacts[index].education,
                                      )),
                            ));
                  },
                ),
        ));
  }
}

class Contact {
  final String number;
  final String name;
  final String book;
  final String image;
  final String birth;
  final String nation;
  final String education;

  Contact(
      {required this.number,
      required this.name,
      required this.book,
      required this.image,
      required this.birth,
      required this.nation,
      required this.education});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      number: json['number'],
      name: json['name'],
      book: json['book'],
      image: json['image'],
      birth: json['birth'],
      nation: json['nation'],
      education: json['education'],
    );
  }
}
