import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  final _scopes = ['https://www.googleapis.com/auth/cloud-platform'];
  Map<String, dynamic>? _secrets;

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    final secrets = await rootBundle.loadString('assets/secrets.json');
    setState(() {
      _secrets = jsonDecode(secrets);
    });
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final text = await _extractTextFromImage(File(pickedImage.path));
      final bookDetails = await _identifyBookDetails(text);
      setState(() {
        _image = pickedImage;
        _titleController.text = bookDetails['title'] ?? '';
        _authorController.text = bookDetails['author'] ?? '';
      });
    }
  }

  Future<String> _getAccessToken() async {
    if (_secrets == null) {
      throw Exception('Secrets not loaded');
    }

    var credentials =
        ServiceAccountCredentials.fromJson(jsonEncode(_secrets!['VisionAI']));
    var client = await clientViaServiceAccount(credentials, _scopes);
    return client.credentials.accessToken.data;
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    final accessToken = await _getAccessToken();
    final visionEndpoint = 'https://vision.googleapis.com/v1/images:annotate';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestPayload = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    };

    print("before response\n");

    final response = await http.post(
      Uri.parse(visionEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: utf8.encode(jsonEncode(requestPayload)),
    );

    print("after response\n");
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final textAnnotations = jsonResponse['responses'][0]['textAnnotations'];
      if (textAnnotations != null && textAnnotations.isNotEmpty) {
        return textAnnotations[0]['description'];
      }
    } else {
      throw Exception('Failed to extract text from image: ${response.body}');
    }
    return '';
  }

  Future<Map<String, String>> _identifyBookDetails(String text) async {
    if (_secrets == null) {
      throw Exception('Secrets not loaded');
    }

    final openaiEndpoint = 'https://api.openai.com/v1/chat/completions';
    final openaiApiKey = _secrets!['OpenAI'];

    print(text);

    final requestPayload = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {
          "role": "user",
          "content":
              "This is a part of a json file which Google Vision API returned. So, it might be a part of a book's title and author. Extract the book title and author from the following text, only with a comma between title and the author, subsequently, NO other descriptions on your answer except the comma, author, title. You can find the book you know which is same or similar with your answer. it may be English, or Korean:\n$text"
        }
      ],
      "max_tokens": 60,
      "temperature": 0.7,
    };

    print("Before GPT");

    final response = await http.post(
      Uri.parse(openaiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode(requestPayload),
    );

    print("After GPT");
    print(response.statusCode);

    if (response.statusCode == 200) {
      print(response.body);
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final text = jsonResponse['choices'][0]['message']['content'].trim();
      final parts = text.split(',');
      return {
        'title': parts.isNotEmpty ? parts[0].trim() : '',
        'author': parts.length > 1 ? parts[1].trim() : '',
      };
    } else {
      throw Exception('Failed to extract text from image: ${response.body}');
    }
    //return {'title': '', 'author': ''};
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
      body: SingleChildScrollView(
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
