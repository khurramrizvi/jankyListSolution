import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:janky_list/model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String dataUrl =
      'https://rest.apizza.net/mock/71aea1b8ad31a9c8000d1e09231017ad/list';

  ListData data;

  @override
  void initState() {
    super.initState();

    _getData();
  }

  void _getData() async {
    Response res = await get(Uri.parse(dataUrl));

    setState(() {
      data = listDataRawFromJson(res.body).data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: data == null
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverFixedExtentList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return BigItem(
                        listItem: data.list[index],
                      );
                    },
                    childCount: data.list.length,
                  ),
                  itemExtent: 260.0,
                )
              ],
            ),
    );
  }
}

class BigItem extends StatelessWidget {
  final ListItem listItem;

  const BigItem({
    Key key,
    this.listItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.white,
      onTap: () {},
      child: Stack(
        children: [
          /**
           * CAUSE: THE MAIN CAUSE OF JANK COULD BE DUE TO IMAGE LOAD OPERATION ON MAIN THREAD
           * SOLUTION/APPROACH: IF WE COULD DELAY THE LOADING OF IMAGES IN MAIN THREAD AND LOAD IT AFTER SOMETIME,
           * IT WOULD RESULT IN SMOOTHER SCROLL AND REDUCED JANK
           * TESTING: TESTED OUT WITH RELEASE BUILD ON ANDROID and WEB, JANK FREE EXPERIENCE ACHIEVED :)
           */

          //a future builder to display the image delayed, to ensure scroll remain smooth
          FutureBuilder<Widget>(
            future: customImageBuilder(listItem.article.cover),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.hasData) {
                return Container(
                  width: double.infinity,
                  height: 260,
                  child: asyncSnapshot.data,
                );
              } else {
                return Container(
                  width: double.infinity,
                  height: 260,
                  color: Colors.white,
                );
              }
            },
          ),
          Container(
            height: 260,
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: 130),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.fromLTRB(16, 21, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.0],
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0),
                    Color.fromRGBO(0, 0, 0, 0.6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '#',
                        style: TextStyle(
                          color: Color(0xffF50627),
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${listItem.channel.name}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  Text(
                    '${listItem.article.title}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'NotoSerifSC',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //after a delay of 900ms(found out after experminting), cached image is retrun which results in jank free scrolling
  Future<Widget> customImageBuilder(String imageUrl) async {
    return await Future.delayed(Duration(milliseconds: 900))
        .then((value) => CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: 100,
              width: 100,
              memCacheHeight: 260,
              memCacheWidth: 480,
              maxHeightDiskCache: 260,
              maxWidthDiskCache: 480,
            ));
  }
}
