import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'add_book_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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

  Widget displayImage(String imagePath) {
    if (!imagePath.startsWith('assets/')) {
      return Image.file(File(imagePath),
          fit: BoxFit.cover, // 변경된 부분
          width: MediaQuery.of(context).size.width * 0.9);
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath,
          fit: BoxFit.cover, // 변경된 부분
          width: MediaQuery.of(context).size.width * 0.9);
    } else {
      return Center(
        child: Text('Invalid image path'),
      );
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
                child: displayImage(imagePath),
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
  final int ID;

  Book(
      {required this.ID,
      required this.book,
      required this.image,
      required this.info,
      required this.author});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
        ID: json['ID'],
        author: json['author'],
        book: json['book'],
        image: json['image'],
        info: json['info']);
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'author': author,
      'book': book,
      'image': image,
      'info': info,
    };
  }
}

class _GalleryState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  int numColumn = 3;
  final maxColumn = 4, minColumn = 2;
  Timer? _debounce;

  List<Book> imageUrls = [];
  String selectedCategory = 'Title';
  List<String> categories = ['Title', 'Author'];
  List<Book> filteredBook = [];
  Set<Book> _selectedBooks = Set<Book>();
  bool _isDeleteMode = false;

  late AnimationController _controller;
  bool _isExpanded = false;

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    _searchController.addListener(filterItems);
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleButtons() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = !_isExpanded;
        _controller.forward();
      });
    } else {
      _controller.reverse().then((_) {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      });
    }
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
        imageUrls.sort((a, b) => a.ID.compareTo(b.ID));
        filteredBook = imageUrls;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        _selectedBooks.clear();
      }
    });
  }

  void _deleteSelectedBooks() async {
    // 선택된 책들의 ID 목록을 가져옵니다.
    List<int> selectedIds = _selectedBooks.map((book) => book.ID).toList();

    setState(() {
      imageUrls.removeWhere((book) => _selectedBooks.contains(book));
      filteredBook.removeWhere((book) => _selectedBooks.contains(book));
      _selectedBooks.clear();
      _isDeleteMode = false;
    });

    // JSON 파일에 저장
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String jsonFilePath = '${documentsDirectory.path}/books.json';
    File jsonFile = File(jsonFilePath);
    String jsonString = jsonEncode(imageUrls);
    await jsonFile.writeAsString(jsonString);

    // 데이터베이스에서 삭제
    try {
      String dbPath = p.join(documentsDirectory.path, 'book.db');
      Database db = await openDatabase(dbPath, version: 1);

      // 데이터베이스에서 선택된 책들을 삭제
      for (int id in selectedIds) {
        await db.delete('Book', where: 'id = ?', whereArgs: [id]);
      }

      print('Selected books deleted from database.');
    } catch (e) {
      print("Error deleting books from database: $e");
    }
  }

  Widget displayImage(String imagePath) {
    if (!imagePath.startsWith('assets/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
      );
    } else {
      return Center(
        child: Text('Invalid image path'),
      );
    }
  }

  Widget _buildButton(
      {required IconData icon,
      required double angle,
      required double distance,
      required String tag}) {
    const b = 0.85;
    const a = -(b * b) / (1 - 2 * b);
    const P = 1 / (1 - 2 * b);
    if (tag == "add") {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = Offset.fromDirection(
              angle + 1 / 3 * 3.14 * (1 - _controller.value),
              (P * (_controller.value - b) * (_controller.value - b) + a) *
                  distance);
          return Transform.translate(
            offset: offset,
            child: FloatingActionButton(
              heroTag: tag,
              mini: true,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookAdd()),
                );

                // pop 후에 수행할 작업
                print("Reloading!!!");
                // 애플리케이션 문서 디렉토리 경로 가져오기
                Directory documentsDirectory =
                    await getApplicationDocumentsDirectory();
                String dbPath = p.join(documentsDirectory.path, 'book.db');

                // assets 폴더에서 데이터베이스 파일을 복사
                ByteData data =
                    await rootBundle.load('assets/database/book.db');
                List<int> bytes = data.buffer
                    .asUint8List(data.offsetInBytes, data.lengthInBytes);
                File dbFile = File(dbPath);
                if (!(await dbFile.exists())) {
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
                String jsonFilePath =
                    p.join(documentsDirectory.path, 'books.json');

                // JSON 파일에 저장
                File jsonFile = File(jsonFilePath);
                await jsonFile.writeAsString(jsonString);

                print('Data saved to JSON file: $jsonFilePath');

                try {
                  Directory documentsDirectory =
                      await getApplicationDocumentsDirectory();
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
                    imageUrls = List<Book>.from(
                        data.map((item) => Book.fromJson(item)));
                    imageUrls.sort((a, b) => a.book.compareTo(b.book));
                    filteredBook = imageUrls;
                    filterItems();
                  });
                } catch (e) {
                  print("Error loading data: $e");
                }
              },
              child: Icon(icon),
            ),
          );
        },
      );
    } else if (tag == "remove")
      // ignore: curly_braces_in_flow_control_structures
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = Offset.fromDirection(
              angle + 1 / 2 * 3.14 * (1 - _controller.value),
              (P * (_controller.value - b) * (_controller.value - b) + a) *
                  distance);
          return Transform.translate(
            offset: offset,
            child: FloatingActionButton(
              heroTag: tag,
              mini: true,
              onPressed: _toggleDeleteMode,
              child: Icon(icon),
            ),
          );
        },
      );
    else
      // ignore: curly_braces_in_flow_control_structures
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = Offset.fromDirection(
              angle + 1 / 8 * 3.14 * (1 - _controller.value),
              _controller.value * distance);
          return Transform.translate(
            offset: offset,
            child: FloatingActionButton(
              heroTag: tag,
              mini: true,
              onPressed: () {
                print("Pressed");
              },
              child: Icon(icon),
            ),
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.transparent,
          BlendMode.multiply,
        ),
        child: Scaffold(
          // appBar: AppBar(
          //   title: Text("Gallery"),
          //   actions: [
          //     if (_isDeleteMode)
          //       IconButton(
          //           onPressed: _deleteSelectedBooks, icon: Icon(Icons.delete))
          //   ],
          // ),
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
                    if (_isDeleteMode)
                      IconButton(
                          onPressed: _deleteSelectedBooks,
                          icon: Icon(Icons.delete))
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Stack(children: [
                    imageUrls.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : GestureDetector(
                            onScaleUpdate: (ScaleUpdateDetails details) {
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();
                              _debounce =
                                  Timer(const Duration(milliseconds: 100), () {
                                setState(() {
                                  if (details.scale > 1)
                                    numColumn++;
                                  else if (details.scale < 1) numColumn--;
                                  if (numColumn > maxColumn)
                                    numColumn = maxColumn;
                                  if (numColumn < minColumn)
                                    numColumn = minColumn;
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
                                              imagePath:
                                                  filteredBook[index].image,
                                              book: filteredBook[index].book,
                                              info: filteredBook[index].info,
                                              author:
                                                  filteredBook[index].author,
                                            ),
                                          ));
                                    },
                                    child: Center(
                                      child: Stack(
                                        children: [
                                          Hero(
                                            tag: filteredBook[index].image,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8.0), // 모서리 둥글기 설정
                                                child: AspectRatio(
                                                  aspectRatio: 1, // 필요한 비율로 설정
                                                  child: displayImage(
                                                      filteredBook[index]
                                                          .image),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_isDeleteMode)
                                            Positioned(
                                              child: Checkbox(
                                                value: _selectedBooks.contains(
                                                    filteredBook[index]),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedBooks.add(
                                                          filteredBook[index]);
                                                    } else {
                                                      _selectedBooks.remove(
                                                          filteredBook[index]);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                          //color: Colors.amber,
                          width: 200,
                          height: 200,
                          child: ColorFiltered(
                              colorFilter: _isExpanded && !_isDeleteMode
                                  ? ColorFilter.mode(
                                      Colors.black.withOpacity(0.5),
                                      BlendMode.overlay,
                                    )
                                  : ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.bottomRight,
                                children: [
                                  if (_isExpanded) ...[
                                    _buildButton(
                                        icon: Icons.add,
                                        angle: -5 / 8 * 3.14,
                                        distance: 100,
                                        tag: 'add'),
                                    _buildButton(
                                        icon: Icons.remove,
                                        angle: -7 / 8 * 3.14,
                                        distance: 100,
                                        tag: 'remove'),
                                  ],
                                  FloatingActionButton(
                                    //focusColor: Colors.amber,
                                    onPressed: _toggleButtons,
                                    child: Icon(_isExpanded
                                        ? Icons.close
                                        : Icons.more_vert),
                                  ),
                                ],
                              ))),
                    ),
                  ]),
                ),
                SizedBox(height: 10),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     ElevatedButton(
                //       onPressed: () async {
                //         await Navigator.push(
                //           context,
                //           MaterialPageRoute(builder: (context) => BookAdd()),
                //         );

                //         // pop 후에 수행할 작업
                //         print("Reloading!!!");
                //         // 애플리케이션 문서 디렉토리 경로 가져오기
                //         Directory documentsDirectory =
                //             await getApplicationDocumentsDirectory();
                //         String dbPath = p.join(documentsDirectory.path, 'book.db');

                //         // assets 폴더에서 데이터베이스 파일을 복사
                //         ByteData data =
                //             await rootBundle.load('assets/database/book.db');
                //         List<int> bytes = data.buffer
                //             .asUint8List(data.offsetInBytes, data.lengthInBytes);
                //         File dbFile = File(dbPath);
                //         if (!(await dbFile.exists())) {
                //           await dbFile.writeAsBytes(bytes, flush: true);
                //           print('Database copied to ${dbFile.path}');
                //         }

                //         // 데이터베이스 연결
                //         Database db = await openDatabase(dbPath, version: 1);

                //         // 데이터베이스에서 데이터 읽기
                //         List<Map<String, dynamic>> bookList =
                //             await db.query('Book');

                //         // JSON 데이터로 변환
                //         String jsonString = jsonEncode(bookList);

                //         // JSON 파일 경로 설정
                //         String jsonFilePath =
                //             p.join(documentsDirectory.path, 'books.json');

                //         // JSON 파일에 저장
                //         File jsonFile = File(jsonFilePath);
                //         await jsonFile.writeAsString(jsonString);

                //         print('Data saved to JSON file: $jsonFilePath');

                //         try {
                //           Directory documentsDirectory =
                //               await getApplicationDocumentsDirectory();
                //           String jsonFilePath =
                //               '${documentsDirectory.path}/books.json';

                //           File jsonFile = File(jsonFilePath);
                //           String response;

                //           if (await jsonFile.exists()) {
                //             // 문서 디렉토리에서 JSON 파일 읽기
                //             response = await jsonFile.readAsString();
                //             print("Read from DB");
                //           } else {
                //             // assets 폴더에서 JSON 파일 읽기
                //             print("Read from assets");
                //             response =
                //                 await rootBundle.loadString('assets/books.json');
                //             // JSON 파일을 문서 디렉토리에 저장
                //             await jsonFile.writeAsString(response);
                //           }

                //           final data = json.decode(response);
                //           setState(() {
                //             imageUrls = List<Book>.from(
                //                 data.map((item) => Book.fromJson(item)));
                //             imageUrls.sort((a, b) => a.book.compareTo(b.book));
                //             filteredBook = imageUrls;
                //             filterItems();
                //           });
                //         } catch (e) {
                //           print("Error loading data: $e");
                //         }
                //       },
                //       child: Text('Add Book..'),
                //       style: ElevatedButton.styleFrom(
                //         foregroundColor: Color.fromARGB(255, 0, 0, 0),
                //         minimumSize: Size(100, 40), // 버튼 크기 지정
                //         padding: EdgeInsets.symmetric(
                //             horizontal: 16, vertical: 8), // 버튼 내부 패딩
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12.0),
                //         ),
                //       ),
                //     ),
                //     SizedBox(width: 20), // 버튼 사이의 간격
                //     ElevatedButton(
                //       onPressed: _toggleDeleteMode,
                //       child: Text(_isDeleteMode ? 'Cancel' : 'Delete Book'),
                //       style: ElevatedButton.styleFrom(
                //         foregroundColor: Color.fromARGB(255, 0, 0, 0),
                //         minimumSize: Size(100, 40), // 버튼 크기 지정
                //         padding: EdgeInsets.symmetric(
                //             horizontal: 16, vertical: 8), // 버튼 내부 패딩
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12.0),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ));
  }
}
