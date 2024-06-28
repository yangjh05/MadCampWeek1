import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutterproj/contacts_page.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class ZoomableImage extends StatefulWidget {
  final String imagePath, author, info, book;
  ZoomableImage(
      {required this.imagePath,
      required this.author,
      required this.info,
      required this.book});

  @override
  FullScreenImagePage createState() => FullScreenImagePage(
      imagePath: imagePath, author: author, info: info, book: book);
}

class FullScreenImagePage extends State<ZoomableImage> {
  TransformationController _transformationController =
      TransformationController();
  ScrollController _scrollController = ScrollController();
  double _currentScale = 1.0;
  bool _isBottomSheetVisible = false;
  final String imagePath, author, info, book;
  FullScreenImagePage(
      {required this.imagePath,
      required this.author,
      required this.info,
      required this.book});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 0.0 && !_isBottomSheetVisible) {
      _isBottomSheetVisible = true;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book: $book',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                info,
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 16.0),
              Text(
                'Author',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Text(
                author,
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      ).whenComplete(() {
        _isBottomSheetVisible = false;
      });
    }
  }

  void _zoomAtPosition(TapDownDetails details, double scale) {
    setState(() {
      final Matrix4 transform = _transformationController.value.clone();
      final Vector3 translation = transform.getTranslation();

      if (scale > _currentScale) {
        final double deltaX = details.localPosition.dx - translation.x;
        final double deltaY = details.localPosition.dy - translation.y;
        final double newX = deltaX * (scale - 1);
        final double newY = deltaY * (scale - 1);

        _transformationController.value = Matrix4.identity()
          ..scale(scale)
          ..translate(-newX / scale, -newY / scale);
      } else {
        _transformationController.value = Matrix4.identity();
      }

      _currentScale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < 0) {
                  _scrollListener();
                }
              },
              onTap: () {
                Navigator.pop(context);
              },
              onDoubleTapDown: (TapDownDetails details) {
                if (_transformationController.value.getMaxScaleOnAxis() < 2.5)
                  _zoomAtPosition(details, 2.5);
                else
                  _zoomAtPosition(details, 1.0);
              },
              child: Hero(
                tag: imagePath,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: EdgeInsets.all(20.0),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: Image.asset(imagePath),
                ),
              ),
            ),
          ),
        ));
  }
}

class GalleryPage extends StatefulWidget {
  @override
  _GalleryState createState() => _GalleryState();
}

class Book {
  final String book, image, info, author;

  Book(
      {required this.book,
      required this.image,
      required this.info,
      required this.author});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
        author: json['author'],
        book: json['book'],
        image: json['image'],
        info: json['info']);
  }
}

class _GalleryState extends State<GalleryPage> {
  int numColumn = 3;
  final maxColumn = 4, minColumn = 2;
  Timer? _debounce;

  List<Book> imageUrls = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final String response = await rootBundle.loadString('assets/books.json');
    final data = json.decode(response);
    setState(() {
      imageUrls = List<Book>.from(data.map((item) => Book.fromJson(item)));
      imageUrls.sort((a, b) => a.book.compareTo(b.book));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Gallery"),
        ),
        body: imageUrls.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: GestureDetector(
                  onScaleUpdate: (ScaleUpdateDetails details) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 100), () {
                      setState(() {
                        if (details.scale > 1.5)
                          numColumn++;
                        else if (details.scale < 0.8) numColumn--;
                        if (numColumn > maxColumn) numColumn = maxColumn;
                        if (numColumn < minColumn) numColumn = minColumn;
                      });
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: GridView.builder(
                      key: ValueKey<int>(numColumn),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: numColumn,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ZoomableImage(
                                      imagePath: imageUrls[index].image,
                                      book: imageUrls[index].book,
                                      info: imageUrls[index].info,
                                      author: imageUrls[index].author,
                                    ),
                                  ));
                            },
                            child: Hero(
                              tag: imageUrls[index],
                              child: Image.asset(imageUrls[index].image),
                            ));
                      },
                    ),
                  ),
                ),
              ));
  }
}
