import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class TodaysBookPage extends StatefulWidget {
  const TodaysBookPage({super.key});

  @override
  _TodaysBookPageState createState() => _TodaysBookPageState();
}

class _TodaysBookPageState extends State<TodaysBookPage> {
  int _currentBookIndex = 0;
  Timer? _timer;
  List<String> _bookImages = [];

  Widget displayImage(String imagePath) {
    if (!imagePath.startsWith('assets/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.fill,
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.fill,
      );
    } else {
      return Center(
        child: Text('Invalid image path'),
      );
    }
  }

  Future<void> loadData() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String jsonFilePath = '${documentsDirectory.path}/books.json';

      File jsonFile = File(jsonFilePath);
      String response;

      if (await jsonFile.exists()) {
        // 문서 디렉토리에서 JSON 파일 읽기
        response = await jsonFile.readAsString();
        print("Read from DB");
      } else {
        // assets 폴더에서 JSON 파일 읽기
        print("Read from assets");
        response = await rootBundle.loadString('assets/books.json');
        // JSON 파일을 문서 디렉토리에 저장
        await jsonFile.writeAsString(response);
      }

      final List<dynamic> data = json.decode(response);
      setState(() {
        _bookImages = data.map((item) => item['image'] as String).toList();
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void _startSlideshow() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _currentBookIndex = (_currentBookIndex + 1) % _bookImages.length;
      });
    });
  }

  void _stopSlideshow() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bookImages.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Spacer(),
                  Text(
                    "Today's Book",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 400,
                    child: displayImage(_bookImages[_currentBookIndex]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _startSlideshow,
                        child: Text('Start'),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _stopSlideshow,
                        child: Text('Stop'),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            ),
    );
  }
}
