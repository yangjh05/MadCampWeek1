import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class TodaysBookPage extends StatefulWidget {
  const TodaysBookPage({super.key});

  @override
  _TodaysBookPageState createState() => _TodaysBookPageState();
}

class _TodaysBookPageState extends State<TodaysBookPage>
    with TickerProviderStateMixin {
  int _currentBookIndex = -1;
  Timer? _timer;
  List<String> _bookImages = [];
  List<String> _bookTitle = [];
  List<String> _bookInfo = [];
  List<String> _bookIntro = [];
  bool showSecond = true;
  int counter = 0;

  Widget displayImage(String imagePath) {
    if (_currentBookIndex == -1) {
      return const Center(
        child: Text(
          '?',
          style: TextStyle(fontSize: 200, color: Colors.white),
        ),
      );
    }

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
        _bookTitle = data.map((item) => item['book'] as String).toList();
        _bookInfo = data.map((item) => item['info'] as String).toList();
        _bookIntro = data.map((item) => item['intro'] as String).toList();
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
    setState(() {
      _currentBookIndex = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _currentBookIndex = (_currentBookIndex + 1) % _bookImages.length;
      });
    });
  }

  void _stopSlideshow() {
    _timer?.cancel();
    _timer = null;
    counter = 0; // counter 초기화
    showSecond = true;
    _showPopup();
  }

  void _showPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Timer.periodic(Duration(seconds: 1), (Timer timer) {
                if (counter >= 1) {
                  timer.cancel();
                } else {
                  setState(() {
                    showSecond = !showSecond;
                    counter++;
                  });
                }
              });
              return Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Container(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: _currentBookIndex != -1
                                  ? Image.asset(
                                      _bookImages[_currentBookIndex],
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Text(
                                        '?',
                                        style: TextStyle(
                                            fontSize: 200, color: Colors.white),
                                      ),
                                    ),
                              secondChild: Image.network(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfMfoLneHJr_RZ8g7EU1CoriJSx5PXHZMFgg&s',
                                width: 150,
                                height: 200,
                                fit: BoxFit.fill,
                              ),
                              crossFadeState: showSecond
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: Duration(seconds: 1),
                            ),
                            CustomPaint(
                              size: Size(300, 10),
                              painter: TrapezoidPainter(),
                            ),
                            Container(
                              width: 300,
                              height: 15,
                              color: Color.fromARGB(255, 205, 193, 175),
                            ),
                            const SizedBox(height: 30),
                            AutoSizeText(
                              _currentBookIndex != -1
                                  ? _bookTitle[_currentBookIndex]
                                  : '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              minFontSize: 8,
                              overflowReplacement: Text(
                                _currentBookIndex != -1
                                    ? _bookTitle[_currentBookIndex]
                                    : '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            AutoSizeText(
                              _currentBookIndex != -1
                                  ? _bookIntro[_currentBookIndex]
                                  : '',
                              textAlign: TextAlign.justify,
                              style: TextStyle(fontSize: 16),
                              maxLines: 3,
                              minFontSize: 8,
                              overflowReplacement: Text(
                                _currentBookIndex != -1
                                    ? _bookIntro[_currentBookIndex]
                                    : '',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0.0,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          print("closing");
                          _currentBookIndex = -1;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) {
      // 팝업 닫힐 때 ? 표시
      setState(() {
        _currentBookIndex = -1;
      });
    });
  }

  void _showAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actionsPadding: EdgeInsets.only(top: 5, bottom: 1),
        title: const Text('Press the start button first'),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
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
                  const Spacer(),
                  const Text(
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
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: displayImage(_currentBookIndex == -1
                        ? ''
                        : _bookImages[_currentBookIndex]),
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

class TrapezoidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 183, 172, 155)
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.9, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
