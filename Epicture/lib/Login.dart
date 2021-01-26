import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'User.dart';
import 'MainPage.dart';

class Login extends StatefulWidget {
  @override
  LoginState createState() => new LoginState();
}

class LoginState extends State<Login> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  refreshToken() {
    Map<String, String> header = {};
    header["Authorization"] = "Bearer " + User.accessToken;
    var uri = "https://api.imgur.com/oauth2/token";
    var data = {
      "refresh_token": User.refreshToken,
      "client_id": User.clientID,
      "client_secret": User.clientSecret,
      "grant_type": "refresh_token"
    };
    http.post(
      Uri.encodeFull(uri),
      headers: header,
      body: data,
    );
  }

  @override
  void initState() {
    super.initState();

    flutterWebviewPlugin.onUrlChanged.listen((String url) {
      url = url.replaceFirst('#', '?');
      Uri uri = Uri.dataFromString(url);
      print("URL OK : $url");
      if (uri.queryParameters["access_token"] != null) {
        setState(() {
          print("${uri.queryParameters["access_token"]}");
          User.accessToken = uri.queryParameters["access_token"];
          User.expiresIn = uri.queryParameters["expires_in"];
          User.tokenType = uri.queryParameters["token_type"];
          User.refreshToken = uri.queryParameters["refresh_token"];
          User.username = uri.queryParameters["account_username"];
          User.id = uri.queryParameters["account_id"];
          User.clientID = "33a7edc010e3617";
          User.clientSecret = "d45d5af1c43029051f6d20150707ab71cdec0400";
        });
        flutterWebviewPlugin.close();
        refreshToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return (User.accessToken == null)
        ? WebviewScaffold(
            url:
                "https://api.imgur.com/oauth2/authorize?client_id=33a7edc010e3617&response_type=token",
          )
        : MainPage();
  }
}
