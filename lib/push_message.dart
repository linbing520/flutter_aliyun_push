

  class PushMessage extends Object {

    String messageId;
    String appId;
    String title;
    String content;
    String traceInfo;

  PushMessage(this.messageId,this.appId,this.title,this.content,this.traceInfo,);

  PushMessage.fromJson(Map<String, dynamic> json)
        : messageId = json['messageId'],
          appId = json['appId'],
          title = json['title'],
          content = json['content'],
          traceInfo = json['traceInfo'];

    Map<String, dynamic> toJson() =>
        {
          'messageId': messageId,
          'appId': appId,
          'title': title,
          'content': content,
          'traceInfo': traceInfo,
        };

}


  class PushNotification extends Object {

    String title;
    String summary;
    Map<dynamic, dynamic> extraMap;

    PushNotification(this.title,this.summary,this.extraMap);

    PushNotification.fromJson(Map<String, dynamic> json)
        : title = json['title'],
          summary = json['summary'],
          extraMap = json['extraMap'];

    Map<String, dynamic> toJson() =>
        {
          'title': title,
          'summary': summary,
          'extraMap': extraMap,
        };

  }
  



  
