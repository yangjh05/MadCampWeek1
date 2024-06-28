import 'package:flutter/material.dart';

class SecondContacts extends StatelessWidget {
  final String name;
  final String phone;

  SecondContacts({required this.name, required this.phone});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ContactDetail(name: name, phone: phone),
    );
  }
}

class ContactDetail extends StatelessWidget {
  final String name;
  final String phone;
  ContactDetail({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, color: Colors.black),
                ),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
