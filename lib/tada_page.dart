import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TadaPage extends StatefulWidget {
  final String bookImage;
  final String title;
  final String info;

  TadaPage({required this.bookImage, required this.title, required this.info});

  @override
  _TadaPageState createState() => _TadaPageState();
}

class _TadaPageState extends State<TadaPage> {
  bool _showBookImage = false;

  @override
  void initState() {
    super.initState();
    _startFadeOut();
  }

  void _startFadeOut() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _showBookImage = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tada Page'),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: Color.fromARGB(255, 245, 241, 229), // 배경색 설정
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _showBookImage ? 1.0 : 0.0,
                    duration: Duration(seconds: 1),
                    child: widget.bookImage.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(top: 90.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10.0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                widget.bookImage,
                                width: 300 * 0.7,
                                height: 450 * 0.7,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Text(
                            'No Image Available',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  AnimatedOpacity(
                    opacity: _showBookImage ? 0.0 : 1.0,
                    duration: Duration(seconds: 1),
                    child: Padding(
                      padding: EdgeInsets.only(top: 80.0),
                      child: Image.network(
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfMfoLneHJr_RZ8g7EU1CoriJSx5PXHZMFgg&s', // 여기에 외부 URL 이미지를 넣습니다.
                        width: 300 * 0.7,
                        height: 450 * 0.7,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ],
              ),
              CustomPaint(
                size: Size(350, 10),
                painter: TrapezoidPainter(),
              ),
              Container(
                width: 350,
                height: 15,
                color: Color.fromARGB(255, 205, 193, 175),
              ),
              SizedBox(height: 30),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  widget.info,
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Spacer(),
            ],
          ),
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
