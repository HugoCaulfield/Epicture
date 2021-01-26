import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

import 'User.dart';
import 'MainPage.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  GetGalleryImages galleryImages;
  String searched;
  String searchGallery = 'https://api.imgur.com/3/gallery/search/';
  int page = 0;

  void searchImages(String sort, String window, String search, String type) {
    String request;
    if (type == null)
      request =
          searchGallery + '$sort/$window/${page.toString()}?q_all=$search';
    else
      request = searchGallery +
          '$sort/$window/${page.toString()}?q_all=$search&q_type=${type.toLowerCase()}';
    http.get(
      request,
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    ).then((response) {
      setState(() {
        galleryImages = GetGalleryImages.fromJson(json.decode(response.body));
        _refreshController.loadComplete();
      });
    });
  }

  voteImage(String id, String vote) {
    http.post(
      'https://api.imgur.com/3/gallery/$id/vote/$vote',
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    );
  }

  favoriteImage(String hash) {
    http.post(
      'https://api.imgur.com/3/image/$hash/favorite',
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    );
  }

  IconButton favButtonState(int index) {
    Color isFavorite;
    if (galleryImages.data[index].favorite)
      isFavorite = Colors.amber;
    else
      isFavorite = Colors.white;
    return IconButton(
        icon: Icon(Icons.star),
        color: isFavorite,
        onPressed: () {
          favoriteImage(galleryImages.data[index].cover);
          if (galleryImages.data[index].favorite)
            galleryImages.data[index].favorite = false;
          else
            galleryImages.data[index].favorite = true;
          setState(() {});
        });
  }

  IconButton upButtonState(int index) {
    Color isUp;
    if (galleryImages.data[index].vote == 'up')
      isUp = Colors.green;
    else
      isUp = Colors.white;
    return IconButton(
      icon: Icon(Icons.thumb_up),
      color: isUp,
      onPressed: () {
        if (galleryImages.data[index].vote == 'up') {
          voteImage(galleryImages.data[index].id, 'veto');
          galleryImages.data[index].vote = null;
          galleryImages.data[index].ups--;
        } else {
          voteImage(galleryImages.data[index].id, 'up');
          if (galleryImages.data[index].vote == 'down')
            galleryImages.data[index].downs--;
          galleryImages.data[index].vote = 'up';
          galleryImages.data[index].ups++;
        }
        setState(() {});
      },
    );
  }

  IconButton downButtonState(int index) {
    Color isDown;
    if (galleryImages.data[index].vote == 'down')
      isDown = Colors.red;
    else
      isDown = Colors.white;
    return IconButton(
      icon: Icon(Icons.thumb_down),
      color: isDown,
      onPressed: () {
        if (galleryImages.data[index].vote == 'down') {
          voteImage(galleryImages.data[index].id, 'veto');
          galleryImages.data[index].vote = null;
          galleryImages.data[index].downs--;
        } else {
          voteImage(galleryImages.data[index].id, 'down');
          if (galleryImages.data[index].vote == 'up')
            galleryImages.data[index].ups--;
          galleryImages.data[index].vote = 'down';
          galleryImages.data[index].downs++;
        }
        setState(() {});
      },
    );
  }

  ListView imageList() {
    for (int i = 0; i < galleryImages.data.length; i++) {
      if (galleryImages.data[i].images == null ||
          (galleryImages.data[i].images.first.type != 'image/jpeg' &&
              galleryImages.data[i].images.first.type != 'image/png')) {
        galleryImages.data.removeAt(i);
        i--;
      }
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: galleryImages.data.length,
      itemBuilder: (context, index) {
        return Column(
          children: <Widget>[
            ClipRRect(
                child: Container(
              child: Wrap(
                children: <Widget>[
                  Center(
                    child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: galleryImages.data[index].images.first.link
                          .replaceFirst('.png', 'l.png')
                          .replaceFirst('.jpeg', 'l.jpeg')
                          .replaceFirst('.jpg', 'l.jpg'),
                      fadeInDuration: Duration(milliseconds: 200),
                      fadeInCurve: Curves.linear,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    child: Text(galleryImages.data[index].title,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        )),
                    padding: EdgeInsets.all(10.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                            child: Row(children: <Widget>[
                              upButtonState(index),
                              Text(galleryImages.data[index].ups.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                  )),
                            ]),
                          ),
                          Row(children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: downButtonState(index),
                            ),
                            Text(galleryImages.data[index].downs.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                )),
                          ]),
                        ],
                      ),
                      Row(children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(left: 5, right: 0),
                          child: favButtonState(index),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                          child: Text(
                              NumberFormat.compact()
                                  .format(galleryImages.data[index].views),
                              style: TextStyle(
                                color: Colors.white,
                              )),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              color: Colors.grey,
            )),
          ],
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          Container(height: 10),
    );
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _loading() async {
    page++;
    searchImages(selectedSort.toLowerCase(), selectedWindow.toLowerCase(),
        searched, selectedType);
  }

  bool onSearch = false;

  List<String> sortFilter = ["Time", "Viral", "Top"];
  List<String> windowFilter = ["Day", "Week", "Month", "Year", "All"];
  List<String> typeFilter = ["PNG", "JPG"];

  String selectedSort = 'Top';
  String selectedWindow = 'All';
  String selectedType;

  buildSF() {
    List<Widget> filterList = List();
    sortFilter.forEach((item) {
      filterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedSort == item,
          onSelected: (selected) {
            setState(() {
              selectedSort = item;
            });
          },
        ),
      ));
    });
    return filterList;
  }

  buildWF() {
    List<Widget> filterList = List();
    windowFilter.forEach((item) {
      filterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedWindow == item,
          onSelected: (selected) {
            setState(() {
              selectedWindow = item;
            });
          },
        ),
      ));
    });
    return filterList;
  }

  buildTF() {
    List<Widget> filterList = List();
    typeFilter.forEach((item) {
      filterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedType == item,
          onSelected: (selected) {
            setState(() {
              if (selectedType == item)
                selectedType = null;
              else
                selectedType = item;
            });
          },
        ),
      ));
    });
    return filterList;
  }

  Widget onSearchFilters() {
    if (onSearch)
      return Wrap(
        children: <Widget>[
          Column(children: <Widget>[
            Wrap(children: buildSF()),
            Wrap(children: buildWF()),
            Wrap(children: buildTF()),
          ])
        ],
        alignment: WrapAlignment.center,
      );
    else
      return Container(height: 10);
  }

//Navigator.push(
//  context,
//  MaterialPageRoute(builder: (context) => MainPage()),
//)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
              icon: Icon(Icons.home_filled, color: Colors.black, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              })
        ],
        title: TextField(
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
          decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black,
              ),
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 18)),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onTap: () {
            setState(() {
              onSearch = true;
            });
          },
          onSubmitted: (inputText) {
            if (inputText != null && inputText != "")
              setState(() {
                onSearch = false;
                page = 0;
                searchImages(selectedSort.toLowerCase(),
                    selectedWindow.toLowerCase(), inputText, selectedType);
                searched = inputText;
              });
          },
        ),
      ),
      body: Center(child: Builder(builder: (context) {
        if (galleryImages != null)
          return Column(
            children: <Widget>[
              onSearchFilters(),
              Expanded(
                child: SmartRefresher(
                  enablePullUp: true,
                  enablePullDown: false,
                  controller: _refreshController,
                  child: imageList(),
                  onLoading: _loading,
                ),
              ),
            ],
          );
        else
          return Column(
            children: <Widget>[
              Wrap(
                children: <Widget>[
                  Column(children: <Widget>[
                    Wrap(children: buildSF()),
                    Wrap(children: buildWF()),
                    Wrap(children: buildTF()),
                  ])
                ],
                alignment: WrapAlignment.center,
              )
            ],
          );
      })),
    );
  }
}
