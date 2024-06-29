import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SecondContacts extends StatelessWidget {
  final String name;
  final String book;
  final String image;
  final String birth;
  final String nation;
  final String education;

  SecondContacts({
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
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              background: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                          margin: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText.rich(
                                textAlign: TextAlign.left,
                                TextSpan(children: [
                                  TextSpan(
                                    text: "| 출생   ",
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: birth,
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.grey),
                                  ),
                                  TextSpan(
                                    text: "\n| 국적   ",
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: nation,
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.grey),
                                  ),
                                  TextSpan(
                                    text: "\n| 학력   ",
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.black),
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
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    , // 작품 이미지 경로 예제
                    fit: BoxFit.cover,
                  ),
                );
              },
              childCount: 2, // 작품의 개수
            ),
          ),
        ],
      ),
    );
  }
}
