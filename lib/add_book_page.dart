import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class BookAdd extends StatefulWidget {
  @override
  _BookAddState createState() => _BookAddState();
}

class _BookAddState extends State<BookAdd> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  Future<bool> submitBook(BuildContext context) async {
    if (_titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      return false;
    }
    await _addBookToDatabase(context); // 비동기 작업
    return true;
  }

  Future<void> _addBookToDatabase(BuildContext context) async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = join(documentsDirectory.path, 'book.db');
      Database db =
          await openDatabase(dbPath, version: 1, onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE Book(id INTEGER PRIMARY KEY, book TEXT, author TEXT, info TEXT, image TEXT)",
        );
      });

      // 데이터베이스에 새 책 추가
      await db.insert(
          'Book',
          {
            'book': _titleController.text,
            'author': _authorController.text,
            'info': _descriptionController.text,
            'image': _image!.path,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      // 데이터베이스에서 최신 데이터 읽어오기
      List<Map<String, dynamic>> bookList = await db.query('Book');

      // JSON 데이터로 변환
      String jsonString = jsonEncode(bookList);

      // JSON 파일 경로 설정
      String jsonFilePath = join(documentsDirectory.path, 'books.json');

      // JSON 파일에 저장
      File jsonFile = File(jsonFilePath);
      await jsonFile.writeAsString(jsonString);
    } catch (e) {
      print("Error adding book to database: $e");
    }
  }

  void _handleSubmit(BuildContext context) async {
    bool isSubmitted = await submitBook(context);
    if (isSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book submitted successfully!'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and select an image.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              // Do nothing, just close the SnackBar
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Book Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 10),
            _image == null
                ? Text('No image selected.')
                : Image.file(File(_image!.path)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _handleSubmit(context),
              child: Text('Submit Book'),
            ),
          ],
        ),
      ),
    );
  }
}
