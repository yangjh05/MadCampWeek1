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
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.grey,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: displayImage(_bookImages[_currentBookIndex]),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _startSlideshow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 45, 26, 0),
                          foregroundColor: Color.fromARGB(255, 255, 255, 255),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('Start'),
                      ),
                      SizedBox(width: 25),
                      ElevatedButton(
                        onPressed: _stopSlideshow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 45, 26, 0),
                          foregroundColor: Color.fromARGB(255, 255, 253, 253),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

void main() {
  runApp(MaterialApp(
    home: TodaysBookPage(),
  ));
}
