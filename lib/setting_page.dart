import 'dart:async';
import 'package:flutter/material.dart';

class TodaysBookPage extends StatefulWidget {
  const TodaysBookPage({super.key});

  @override
  _TodaysBookPageState createState() => _TodaysBookPageState();
}

class _TodaysBookPageState extends State<TodaysBookPage> {
  int _currentBookIndex = 0;
  Timer? _timer;
  final List<String> _bookImages = [
    "assets/image/book1_1.png",
    "assets/image/book1_2.png",
    "assets/image/book2_1.png",
    "assets/image/book2_2.png",
    "assets/image/book3_1.png",
    "assets/image/book3_2.png",
    "assets/image/book4_1.png",
    "assets/image/book5_1.png",
    "assets/image/book5_2.png",
    "assets/image/book6_1.png",
    "assets/image/book6_2.png",
    "assets/image/book7_1.png",
    "assets/image/book7_2.png",
    "assets/image/book8_1.png",
    "assets/image/book8_2.png",
    "assets/image/book9_1.png",
    "assets/image/book9_2.png",
    // 추가 이미지 파일 경로
  ];

  void _startSlideshow() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _currentBookIndex = (_currentBookIndex + 1) % _bookImages.length;
      });
    });
  }

  void _stopSlideshow() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text(
            "Today's Book",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 400,
                child: Image.asset(
                  _bookImages[_currentBookIndex],
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
