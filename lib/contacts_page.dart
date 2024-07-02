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
  List<Contact> filteredCon = [];
  List<Contact> imageUrls = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
    _searchController.addListener(filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterItems() {
    String searchText = _searchController.text;
    bool isEnglish = RegExp(r'[a-zA-Z]').hasMatch(searchText);
    List<Contact> filtered = imageUrls.where((item) {
      final itemLower = item.name.toLowerCase();
      final matchesSearch = isEnglish
          ? itemLower.contains(searchText.toLowerCase())
          : item.name.contains(searchText);
      return matchesSearch;
    }).toList();

    setState(() {
      filteredCon = filtered;
    });
  }

  Future<void> loadContacts() async {
    final String response = await rootBundle.loadString('assets/contacts.json');
    final data = json.decode(response);
    setState(() {
      imageUrls =
          List<Contact>.from(data.map((item) => Contact.fromJson(item)));
      imageUrls.sort((a, b) => a.name.compareTo(b.name));
      contacts = imageUrls;
      filteredCon = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ListView',
        home: Scaffold(
            //appBar: AppBar(title: const Text('Contacts')),
            body: contacts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: false,
                          ),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredCon.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(filteredCon[index].name),
                                subtitle: Text(filteredCon[index].book),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[400],
                                  backgroundImage:
                                      AssetImage(filteredCon[index].image),
                                ),
                                trailing:
                                    const Icon(Icons.keyboard_arrow_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SecondContacts(
                                            number: filteredCon[index].number,
                                            name: filteredCon[index].name,
                                            book: filteredCon[index].book,
                                            image: filteredCon[index].image,
                                            birth: filteredCon[index].birth,
                                            nation: filteredCon[index].nation,
                                            education:
                                                filteredCon[index].education,
                                          )),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )));
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
