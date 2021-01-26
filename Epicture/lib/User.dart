class User {
  static String accessToken;
  static String expiresIn;
  static String tokenType;
  static String refreshToken;
  static String username;
  static String id;
  static String clientID;
  static String clientSecret;
}

class GetGalleryImages {
  List<Data> data;
  bool success;
  int status;

  GetGalleryImages({this.data, this.success, this.status});

  GetGalleryImages.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = new List<Data>();
      json['data'].forEach((v) {
        data.add(new Data.fromJson(v));
      });
    }
    success = json['success'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    data['status'] = this.status;
    return data;
  }
}

class Data {
  String id;
  String title;
  String cover;
  int views;
  String link;
  String vote;
  bool favorite;
  int ups;
  int downs;
  List<Images> images;

  Data(
      {this.id,
      this.title,
      this.cover,
      this.views,
      this.link,
      this.vote,
      this.favorite,
      this.ups,
      this.downs,
      this.images});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    cover = json['cover'];
    views = json['views'];
    link = json['link'];
    vote = json['vote'];
    favorite = json['favorite'];
    ups = json['ups'];
    downs = json['downs'];
    if (json['images'] != null) {
      images = new List<Images>();
      json['images'].forEach((v) {
        images.add(new Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['cover'] = this.cover;
    data['views'] = this.views;
    data['link'] = this.link;
    data['vote'] = this.vote;
    data['favorite'] = this.favorite;
    data['ups'] = this.ups;
    data['downs'] = this.downs;
    if (this.images != null) {
      data['images'] = this.images.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Images {
  String type;
  String link;

  Images({this.type, this.link});

  Images.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['link'] = this.link;
    return data;
  }
}
