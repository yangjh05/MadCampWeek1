import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TodaysBookPage extends StatefulWidget {
  const TodaysBookPage({super.key});

  @override
  _TodaysBookPageState createState() => _TodaysBookPageState();
}

class _TodaysBookPageState extends State<TodaysBookPage> {
  int _currentBookIndex = 0;
  Timer? _timer;
  List<String> _bookImages = [];

  Future<void> loadData() async {
    final String response = await rootBundle.loadString('assets/books.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _bookImages = data.map((item) => item['image'] as String).toList();
    });
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
                    child: Image.asset(
                      _bookImages[_currentBookIndex],
                      fit: BoxFit.fill,
                    ),
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
