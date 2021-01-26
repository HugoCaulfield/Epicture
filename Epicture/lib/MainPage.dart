import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'SearchPage.dart';
import 'User.dart';

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  var accImages;
  var accFavs;
  var goodAccFavs = [];
  GetGalleryImages galleryImages;
  File _image;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black);

  static const List<Widget> _AppBarTitle = <Widget>[
    Text('Home', style: optionStyle),
    Text('Library', style: optionStyle),
    Text('Favorites', style: optionStyle),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _MainPageState() {
    getGallery();
    getImages();
    getFavs();
  }

  getGallery() {
    http.get(
      'https://api.imgur.com/3/gallery/search/top/all/0?q_all=memes',
      headers: {HttpHeaders.authorizationHeader: "Client-ID " + User.clientID},
    ).then((response) {
      setState(() {
        galleryImages = GetGalleryImages.fromJson(json.decode(response.body));
      });
    });
  }

  getImages() {
    http.get(
      'https://api.imgur.com/3/account/${User.username}/images/',
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    ).then((response) {
      setState(() {
        accImages = json.decode(response.body)['data'];
      });
    });
  }

  getFavs() async {
    await http.get(
      'https://api.imgur.com/3/account/${User.username}/favorites/',
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    ).then((response) async {
      accFavs = json.decode(response.body)['data'];
      goodAccFavs.clear();
      for (var i = 0; i < accFavs.length; i++) {
        await http.get(
          'https://api.imgur.com/3/image/' + accFavs[i]['cover'],
          headers: {
            HttpHeaders.authorizationHeader: "Bearer " + User.accessToken
          },
        ).then((response) {
          goodAccFavs += [json.decode(response.body)['data']];
        });
      }
      setState(() {
        accFavs = json.decode(response.body)['data'];
      });
    });
  }

  favoriteImage(String hash) {
    http.post(
      'https://api.imgur.com/3/image/$hash/favorite',
      headers: {HttpHeaders.authorizationHeader: "Bearer " + User.accessToken},
    ).then((response) {
      setState(() {
        getFavs();
      });
    });
  }

  uploadImage(File image, String description) {
    List<int> imageBytes = image.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    http.post('https://api.imgur.com/3/upload', headers: {
      HttpHeaders.authorizationHeader: "Bearer " + User.accessToken
    }, body: {
      'image': base64Image,
      'type': 'base64',
      'description': description
    }).then((response) {
      setState(() {
        getImages();
      });
    });
  }

  final inputDesc = TextEditingController();

  Future getImage() async {
    final picker = ImagePicker();
    final image = await picker.getImage(source: ImageSource.gallery);
    if (image != null)
      setState(() {
        _image = File(image.path);
        showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text('Upload to Imgur'),
                  titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  backgroundColor: Theme.of(context).canvasColor,
                  content: Image.file(_image),
                  actions: <Widget>[
                    Container(
                        child: TextField(
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          controller: inputDesc,
                          decoration: InputDecoration(
                              hintText: "Description...",
                              hintStyle:
                                  TextStyle(color: Colors.black, fontSize: 18)),
                          textInputAction: TextInputAction.done,
                        ),
                        width: 235),
                    Padding(
                        padding: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            uploadImage(_image, inputDesc.text);
                            Navigator.of(context).pop();
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80.0)),
                          padding: const EdgeInsets.all(0.0),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [Colors.red, Colors.purple],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(80.0)),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                  maxWidth: 125,
                                  maxHeight: 50,
                                  minWidth: 88.0,
                                  minHeight:
                                      36.0), // min sizes for Material buttons
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        )),
                  ],
                ));
      });
  }

  Container imagesGrid(int index) {
    return Container(
        padding: EdgeInsets.all(2),
        child: GestureDetector(
          child: FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: accImages[index]['link']
                .toString()
                .replaceFirst('.png', 'm.png')
                .replaceFirst('.jpeg', 'm.jpeg')
                .replaceFirst('.jpg', 'm.jpg'),
            fadeInDuration: new Duration(milliseconds: 200),
            fadeInCurve: Curves.linear,
            fit: BoxFit.cover,
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      title: Text(accImages[index]['description'].toString()),
                      titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      backgroundColor: Colors.white,
                      content: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: accImages[index]['link']
                            .toString()
                            .replaceFirst('.png', 'l.png')
                            .replaceFirst('.jpeg', 'l.jpeg')
                            .replaceFirst('.jpg', 'l.jpg'),
                      ),
                      actions: <Widget>[
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: new Icon(
                                Icons.remove_red_eye,
                                color: Colors.black,
                              ),
                            ),
                            Text(NumberFormat.compact()
                                .format(accImages[index]['views'])),
                            IconButton(
                                icon: Icon(Icons.favorite_border_outlined,
                                    color: Colors.black, size: 35),
                                onPressed: () {
                                  favoriteImage(accImages[index]['id']);
                                  Navigator.of(context).pop();
                                })
                          ],
                        )
                      ],
                    ));
          },
        ));
  }

  Container favGrid(int index) {
    return Container(
        padding: EdgeInsets.all(2),
        child: GestureDetector(
          child: FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: goodAccFavs[index]['link'],
            fadeInDuration: Duration(milliseconds: 200),
            fadeInCurve: Curves.linear,
            fit: BoxFit.cover,
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      title: Text(' '),
                      titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      backgroundColor: Theme.of(context).canvasColor,
                      content: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: goodAccFavs[index]['link'],
                      ),
                      actions: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.remove_red_eye,
                                color: Colors.black,
                              ),
                            ),
                            Text(NumberFormat.compact()
                                .format(goodAccFavs[index]['views'])),
                            IconButton(
                                icon: Icon(Icons.favorite,
                                    color: Colors.red, size: 35),
                                onPressed: () {
                                  favoriteImage(goodAccFavs[index]['id']);
                                  Navigator.of(context).pop();
                                })
                          ],
                        )
                      ],
                    ));
          },
        ));
  }

  Container postGalery() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
        child: GridView.builder(
            itemCount: accImages.length,
            shrinkWrap: true,
            gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemBuilder: (context, index) {
              return imagesGrid(index);
            }),
      ),
    );
  }

  Container favGalery() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
        child: GridView.builder(
            itemCount: goodAccFavs.length,
            shrinkWrap: true,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, index) {
              return favGrid(index);
            }),
      ),
    );
  }

  voteImage(String id, String vote) {
    http.post(
      'https://api.imgur.com/3/gallery/$id/vote/$vote',
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

  ListView homeGallery() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle.elementAt(_selectedIndex),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.black,
              size: 35,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          )
        ],
      ),
      body: Center(child: Builder(builder: (context) {
        if (galleryImages == null || accImages == null) {
          return CircularProgressIndicator();
        } else {
          if (_selectedIndex == 1)
            return postGalery();
          else if (_selectedIndex == 2)
            return favGalery();
          else
            return homeGallery();
        }
      })),
      floatingActionButton: FloatingActionButton(
        child: Container(
          width: 60,
          height: 60,
          child: Icon(
            Icons.add,
            size: 30,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Colors.red, Colors.purple],
            ),
          ),
        ),
        onPressed: () {
          getImage();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
