import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'push_message.dart';

typedef OnReceiveMessage = Function(PushMessage);
typedef OnReceiveNotification = Function(PushNotification);
typedef ApiCallback = Function(bool,Object);

class FlutterAliyunPush {
  static const MethodChannel _channel =
      const MethodChannel('aliyun_push');

  static const EventChannel eventChannel = EventChannel("App/Event/Channel", const StandardMethodCodec());
      
  static bool registCallback = false;

  static Function onRegistSuccess;
  static Function onRegistError;
  static OnReceiveNotification onReceiveNotification;
  static OnReceiveMessage onReceiveMessage;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }


  /**
   * 注册原生调用dart
   */
  static  void registCallHandler() {
    if(registCallback) {
      return;
    }
    print("registCallHandler---------------");
    registCallback = true;


    _channel.setMethodCallHandler((call) {
      print("setMethodCallHandler:"+call.method);
      switch(call.method) {
        case "onPushRegistSuccess":
          if(onRegistSuccess != null) {
            onRegistSuccess(call.arguments);
          }
          break;
        case "onPushRegistError":
          if(onRegistError != null) {
            onRegistError(call.arguments);
          }
          break;
        case "onReceiverNotification":
          if(onReceiveNotification != null) {
            var param = call.arguments;
            if(param != null) {
              if(Platform.isIOS) {
                if(param['aps'] != null && param['aps']['alert'] != null) {
                  var content = param['aps']['alert'];
                  var title = content['title'];
                  String body = content['body']; 
                  param = PushNotification(title,body,param);
                }


              }else {
                 param = PushNotification.fromJson(json.decode(param));
              }
            }
            onReceiveNotification(param);
          }
          break;
        case "onReceiverMessage":
          if(onReceiveMessage != null) {
            var param = call.arguments;
            if(param != null) {
              param = PushMessage.fromJson(json.decode(param));
            }
            onReceiveMessage(param);
          }
          break;
      }
    });
    //告诉原生已经有监听了
    if(Platform.isAndroid) {
      _channel.invokeMethod('listened');
    }
  }

  static void  reigistOnRegistSuccess(Function callback) {
    onRegistSuccess = callback;
    registCallHandler();
  }


  static void  reigistOnRegistError(Function callback) {
    onRegistError = callback;
    registCallHandler();
  }

  static void  reigistOnReceiveNotification(OnReceiveNotification callback) {
    onReceiveNotification = callback;
    registCallHandler();
  }

  static void  reigistOnReceiveMessage(OnReceiveMessage callback) {
    onReceiveMessage = callback;
    registCallHandler();
  }



  //api 相关接口
  //绑定账号
  static void bindAccount(String account, ApiCallback callback) {
    _channel.invokeMethod("bindAccount",account).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

  //解绑账号
  static void unbindAccount(ApiCallback callback) {
    _channel.invokeMethod("unbindAccount").then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

  //绑定标签
  static void bindTag(int target,  List<String> tags, String alias, ApiCallback callback) {
    var params = {target:target,tags:tags,alias:alias};
    _channel.invokeMethod("bindTag",params).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

  //解绑标签
  static void unbindTag(int target,  List<String> tags, String alias, ApiCallback callback) {
    var params = {target:target,tags:tags,alias:alias};
    _channel.invokeMethod("unbindTag",params).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

  //查询标签
  static void listTags(int target, ApiCallback callback) {
    _channel.invokeMethod("listTags",target).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }


  //添加别名
  static void addAlias(String alias, ApiCallback callback) {
    _channel.invokeMethod("addAlias",alias).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

  //删除设备别名。
  static void removeAlias(String alias, ApiCallback callback) {
    _channel.invokeMethod("removeAlias",alias).then((value) => {
      callback(true,value)
    }).catchError((e)=>{
      callback(false,e)
    });
  }

    //查询设备别名
    static void listAliases(ApiCallback callback) {
      _channel.invokeMethod("listAliases").then((value) => {
        callback(true,value)
      }).catchError((e)=>{
        callback(false,e)
      });
    }

}


