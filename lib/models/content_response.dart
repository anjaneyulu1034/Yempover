class ContentResponse {
  String? status;
  String? message;
  ContentData? data;

  ContentResponse({this.status, this.message, this.data});

  ContentResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? ContentData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ContentData {
  String? title;
  String? content;
  String? slug;
  String? lastUpdated;

  ContentData({this.title, this.content, this.slug, this.lastUpdated});

  ContentData.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    content = json['content'];
    slug = json['slug'];
    lastUpdated = json['lastUpdated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['content'] = content;
    data['slug'] = slug;
    data['lastUpdated'] = lastUpdated;
    return data;
  }
}
