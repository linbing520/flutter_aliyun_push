# flutter_aliyun_push
阿里云推送，安卓支持厂商推送
使用方便，只需要三个步骤
<br/>
使用步骤：<br/>
dart：<br/>
1.添加注册成功监听
   
        FlutterAliyunPush.reigistOnRegistSuccess((msg){ 
        });

2.添加收到通知监听

     FlutterAliyunPush.reigistOnReceiveNotification((msg){
        var test = json.encode(msg.toJson());
     });



3.添加收到消息监听

     FlutterAliyunPush.reigistOnReceiveMessage((msg){
        var test = json.encode(msg.toJson());
     });

原生集成步骤：<br/>
安卓：<br/>
1.配置信息
android目录下的app目录下的build.gradle文件中
defaultConfig下添加

     manifestPlaceholders = [
                aliyunPushAppKey: "", //阿里云推送appkey
                aliyunPushAppSecret:"",//阿里云推送appsecret
                pushChannelId:"\\1", //安卓8.0后推送需指定渠道id，后台发送推送需要指定相同值（配置中纯数字需要加\\反斜线）
                pushChannelName:"channelname", //安卓8.0后推送需指定用户可以看到的通知渠道的名字.，后台发送推送需要指定相同值（配置中纯数字需要加\\反斜线）
                pushChannelDescrition:"channeldesc", //安卓8.0后推送需指定用户可以看到的通知渠道的描述.，后台发送推送需要指定相同值（配置中纯数字需要加\\反斜线）
                miPushAppId:"\\2882303761517669764", //小米推送Appid （配置中纯数字需要加\\反斜线）
                miPushAppKey:"\\5691766985764", //小米推送AppKey （配置中纯数字需要加\\反斜线）
                huaweiPushAppId:"", //华为推送AppId （配置中纯数字需要加\\反斜线）
                vivoPushAppId:"", //vivo推送AppId （配置中纯数字需要加\\反斜线）
                vivoPushAppKey:"", //vivo推送AppKey （配置中纯数字需要加\\反斜线）
                oppoPushAppKey:"", //oppo推送AppKey （配置中纯数字需要加\\反斜线）
                oppoPushAppSecret:"", //oppo推送AppKey （配置中纯数字需要加\\反斜线）
                meizhuPushAppId:"",  //魅族推送AppId （配置中纯数字需要加\\反斜线）
                meizhuPushAppKey:"",//魅族推送AppKey （配置中纯数字需要加\\反斜线）
        ]

2.初始化推送
自定义AppApplication继承FlutterApplication
onCreate 中调用<br/>
 FlutterAliyunPushPlugin.initPush(this);


ios：<br/>
1.初始化
在AppDelegate添加如下初始化代码：<br/>
[FlutterAliyunPushPlugin initKey:@"" appSecret:@""];

ios推送证书配置参考：<br/>
https://help.aliyun.com/document_detail/30071.html?spm=a2c4g.11174283.6.608.43bd6d16C23L8t
