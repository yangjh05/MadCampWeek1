import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'add_book_page.dart';

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
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
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
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain, // 변경된 부분
                  width: MediaQuery.of(context).size.width * 0.9, // 변경된 부분
                ),
              ),
            ),
          ),
        )));
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
  String selectedCategory = 'Title';
  List<String> categories = ['Title', 'Author'];
  List<Book> filteredBook = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    _searchController.addListener(filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterItems() {
    String searchText = _searchController.text;
    bool isEnglish = RegExp(r'[a-zA-Z]').hasMatch(searchText);
    List<Book> filtered = imageUrls.where((item) {
      if (selectedCategory == 'Title') {
        final itemLower = item.book.toLowerCase();
        final matchesSearch = isEnglish
            ? itemLower.contains(searchText.toLowerCase())
            : item.book.contains(searchText);
        return matchesSearch;
      } else {
        final itemLower = item.author.toLowerCase();
        final matchesSearch = isEnglish
            ? itemLower.contains(searchText.toLowerCase())
            : item.author.contains(searchText);
        return matchesSearch;
      }
    }).toList();

    setState(() {
      filteredBook = filtered;
    });
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

      final data = json.decode(response);
      setState(() {
        imageUrls = List<Book>.from(data.map((item) => Book.fromJson(item)));
        imageUrls.sort((a, b) => a.book.compareTo(b.book));
        filteredBook = imageUrls;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      filterItems();
                    });
                  },
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down),
                ),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: imageUrls.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      onScaleUpdate: (ScaleUpdateDetails details) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 100), () {
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
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        child: GridView.builder(
                          key: ValueKey<int>(numColumn),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: numColumn,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredBook.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ZoomableImage(
                                          imagePath: filteredBook[index].image,
                                          book: filteredBook[index].book,
                                          info: filteredBook[index].info,
                                          author: filteredBook[index].author,
                                        ),
                                      ));
                                },
                                child: Hero(
                                  tag: filteredBook[index].image,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Image.asset(
                                      filteredBook[index].image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ));
                          },
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookAdd()),
                  ),
                  child: Text('Add Book..'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 40), // 버튼 크기 지정
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8), // 버튼 내부 패딩
                  ),
                ),
                SizedBox(width: 10), // 버튼 사이의 간격
                ElevatedButton(
                  onPressed: () {
                    // 버튼 2 클릭 시 동작
                  },
                  child: Text('Delete Book'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 40), // 버튼 크기 지정
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8), // 버튼 내부 패딩
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
