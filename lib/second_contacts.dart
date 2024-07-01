import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SecondContacts extends StatelessWidget {
  final String number;
  final String name;
  final String book;
  final String image;
  final String birth;
  final String nation;
  final String education;

  SecondContacts({
    required this.number,
    required this.name,
    required this.book,
    required this.image,
    required this.birth,
    required this.nation,
    required this.education,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            backgroundColor: Color.fromARGB(255, 176, 183, 187),
            stretch: true,
            onStretchTrigger: () async {
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: 300,
                height: 500,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(image), // 배경 이미지 파일 경로
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            flexibleSpace: FlexibleSpaceBar(
              title: Align(
                alignment: Alignment.bottomRight,
                child: AutoSizeText(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              background: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
              stretchModes: [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          backgroundImage: AssetImage(image),
                        ),
                        SizedBox(height: 16),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 26, color: Colors.black),
                        ),
                        Text(
                          book,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText.rich(
                                textAlign: TextAlign.left,
                                TextSpan(children: [
                                  const TextSpan(
                                    text: "| 출생   ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                        color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: birth,
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.grey),
                                  ),
                                  const TextSpan(
                                    text: "\n| 국적   ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                        color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: nation,
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.grey),
                                  ),
                                  const TextSpan(
                                    text: "\n| 학력   ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                        color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: education,
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.grey),
                                  ),
                                ]),
                                maxLines: 3,
                                minFontSize: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 16),
                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.only(top: 10.0),
                                  padding: EdgeInsets.only(bottom: 10.0),
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color.fromARGB(
                                                  31, 80, 78, 78),
                                              width: 2))),
                                  child: const Text(
                                    "\n대표작품",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                // 이미지 파일 경로 생성
                final String imagePath =
                    'assets/image/book${number}_${index + 1}.png';
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                );
              },
              childCount: 2, // 작품의 개수 (예제)
            ),
          ),
        ],
      ),
    );
  }
}
