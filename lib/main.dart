import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

import 'contacts_page.dart';
import 'gallary_page.dart';
import 'setting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();
  runApp(MyApp());
}

Future<void> initializeDatabase() async {
  // 애플리케이션 문서 디렉토리 경로 가져오기
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String dbPath = join(documentsDirectory.path, 'book.db');

  // assets 폴더에서 데이터베이스 파일을 복사
  ByteData data = await rootBundle.load('assets/database/book.db');
  List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  File dbFile = File(dbPath);
  if (!(await dbFile.exists())) {
    print("DB dont exist");
    await dbFile.writeAsBytes(bytes, flush: true);
    print('Database copied to ${dbFile.path}');
  }

  // 데이터베이스 연결
  Database db = await openDatabase(dbPath, version: 1);

  // 데이터베이스에서 데이터 읽기
  List<Map<String, dynamic>> bookList = await db.query('Book');

  // JSON 데이터로 변환
  String jsonString = jsonEncode(bookList);

  // JSON 파일 경로 설정
  String jsonFilePath = join(documentsDirectory.path, 'books.json');

  // JSON 파일에 저장
  File jsonFile = File(jsonFilePath);
  await jsonFile.writeAsString(jsonString);

  print('Data saved to JSON file: $jsonFilePath');
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
          title: const Text('Bookshelf'),
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
