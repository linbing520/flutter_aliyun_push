package com.flutter.flutter_aliyun_push;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Handler;

import androidx.annotation.NonNull;

import com.alibaba.sdk.android.push.CloudPushService;
import com.alibaba.sdk.android.push.CommonCallback;
import com.alibaba.sdk.android.push.huawei.HuaWeiRegister;
import com.alibaba.sdk.android.push.noonesdk.PushServiceFactory;
import com.alibaba.sdk.android.push.register.MeizuRegister;
import com.alibaba.sdk.android.push.register.MiPushRegister;
import com.alibaba.sdk.android.push.register.OppoRegister;
import com.alibaba.sdk.android.push.register.VivoRegister;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;

import java.util.ArrayList;
import java.util.List;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;

public class FlutterAliyunPushPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

  public static final String TAG = "AliyunPushPlugin";
  public static final String CHANNEL_NAME="aliyun_push";
  private static Context mContext;
  public static Object initializationLock = new Object();
  private MethodChannel aliyunPushPluginChannel;
  private static String lastPushRegistSuccessMessage;
  private static String lastPushRegistErrorMessage;
  public static boolean isPluginAttached; //插件是否被加载到flutter
  public static boolean isFlutterHasListened; //flutter是否已经添加了method监听,没有监听，来消息时，将会放入缓存队列
  private static List<FlutterPushNotification> cachedNotifications = new ArrayList<FlutterPushNotification>(); //未传到dart的消息
  private static List<FlutterPushMessage> cachedMessages = new ArrayList<FlutterPushMessage>(); //未传到dart的消息

  public MethodChannel getAliyunPushPluginChannel() {
    return aliyunPushPluginChannel;
  }

  public FlutterAliyunPushPlugin() {

  }


  @Subscribe()
  public void onMessageEvent(PushMessageEvent event) {
    Log.d(FlutterAliyunPushPlugin.TAG, "onMessageEvent:"+event.eventName);
    if(aliyunPushPluginChannel == null) {
      return;
    }
    if(PushMessageEvent.EVENT_onPushRegistSuccess.equals(event.eventName)
      || PushMessageEvent.EVENT_onPushRegistError.equals(event.eventName)
    ) {
      //初始化
      aliyunPushPluginChannel.invokeMethod(event.eventName,(String)event.params);
    }else if(PushMessageEvent.EVENT_onReceiverMessage.equals(event.eventName)
    || PushMessageEvent.EVENT_onReceiverNotification.equals(event.eventName)) {
      //接受消息
      aliyunPushPluginChannel.invokeMethod(event.eventName,event.getParamsJSONString());
    }
  };


  public static void sendPushNotification(Context context,FlutterPushNotification message) {
    if(FlutterAliyunPushPlugin.isFlutterHasListened) {
      EventBus.getDefault().post(new PushMessageEvent(PushMessageEvent.EVENT_onReceiverNotification,message));
    }else {
      Log.d(FlutterAliyunPushPlugin.TAG, "notification recevie not plugin not attach");
      cachedNotifications.add(message);
    }
  }

  public static void sendPushMessage(Context context,FlutterPushMessage message) {
    if(FlutterAliyunPushPlugin.isFlutterHasListened) {
      EventBus.getDefault().post(new PushMessageEvent(PushMessageEvent.EVENT_onReceiverMessage,message));
    }else {
      Log.d(FlutterAliyunPushPlugin.TAG, "message recevie not plugin not attach");
      cachedMessages.add(message);
    }
  }

  /**
   * 该方法必须在Appcation onCreate中被执行，否则推送会有问题
   * @param context
   */
  public static void initPush(Context context) {
    Log.i(TAG, "start initPush");
    mContext = context;
    PushServiceFactory.init(context);
    initThirdPush(context);
    CloudPushService pushService = PushServiceFactory.getCloudPushService();
    pushService.register(context, new CommonCallback() {
      @Override
      public void onSuccess(String response) {
        Log.d(FlutterAliyunPushPlugin.TAG, "init cloudchannel success");
        synchronized (initializationLock) {
          if(FlutterAliyunPushPlugin.isPluginAttached) {
            EventBus.getDefault().post(new PushMessageEvent(PushMessageEvent.EVENT_onPushRegistSuccess,response));
          }else {
            Log.d(FlutterAliyunPushPlugin.TAG, "instance.aliyunPushPluginChannel null");
            lastPushRegistSuccessMessage = response;
            lastPushRegistErrorMessage = null;
          }
        }

      }
      @Override
      public void onFailed(String errorCode, String errorMessage) {
        Log.d(FlutterAliyunPushPlugin.TAG, "init cloudchannel failed -- errorcode:" + errorCode + " -- errorMessage:" + errorMessage);
        if(FlutterAliyunPushPlugin.isPluginAttached) {
          EventBus.getDefault().post(new PushMessageEvent(PushMessageEvent.EVENT_onPushRegistError,errorMessage));
        }else {
          lastPushRegistErrorMessage = errorMessage;
          lastPushRegistSuccessMessage = null;
        }
      }
    });

  }

  /**
   * 初始化厂商推送
   */
  public static void initThirdPush(Context context) {
    ThirdPushConfig config = new ThirdPushConfig();

    ApplicationInfo appInfo = null;
    try {
      appInfo = context.getPackageManager()
              .getApplicationInfo(context.getPackageName(),
                      PackageManager.GET_META_DATA);
    } catch (PackageManager.NameNotFoundException e) {
      e.printStackTrace();
    }
    if(appInfo == null) {
      return;
    }

    String pushChannelId =  appInfo.metaData.getString("com.flutter.push.channelId");
    String pushChannelName =  appInfo.metaData.getString("com.flutter.push.channelName");
    String pushChanneDescription =  appInfo.metaData.getString("com.flutter.push.channeDescrition");
    initPushVersion(context, pushChannelId,pushChannelName,pushChanneDescription);

    config.miPushAppId = appInfo.metaData.getString("com.mi.push.app_id");
    config.miPushAppKey = appInfo.metaData.getString("com.mi.push.api_key");

    config.huaweiPushAppId = appInfo.metaData.getString("com.huawei.hms.client.appid");

    config.vivoPushAppId = appInfo.metaData.getString("com.vivo.push.app_id");
    config.vivoPushAppKey = appInfo.metaData.getString("com.vivo.push.api_key");

    config.oppoPushAppKey = appInfo.metaData.getString("com.oppo.push.api_key");
    config.oppoPushAppSecret = appInfo.metaData.getString("com.oppo.push.app_secret");

    config.meizhuPushAppId = appInfo.metaData.getString("com.meizhu.push.app_id");
    config.meizhuPushAppKey = appInfo.metaData.getString("com.meizhu.push.api_key");

    // 注册方法会自动判断是否支持小米系统推送，如不支持会跳过注册。
    if(config.miPushAppId != null && config.miPushAppKey != null) {
      MiPushRegister.register(context, config.miPushAppId, config.miPushAppKey);
    }

    // 注册方法会自动判断是否支持华为系统推送，如不支持会跳过注册。
    if(config.huaweiPushAppId != null) {
      HuaWeiRegister.register((Application) context);
    }

    // OPPO通道注册
    if(config.oppoPushAppKey != null && config.oppoPushAppSecret != null) {
      OppoRegister.register(context, config.oppoPushAppKey, config.oppoPushAppSecret); // appKey/appSecret在OPPO开发者平台获取
    }

    // 魅族通道注册
    if(config.meizhuPushAppId != null && config.meizhuPushAppKey != null) {
      MeizuRegister.register(context, config.meizhuPushAppId, config.meizhuPushAppKey); // appId/appkey在魅族开发者平台获取
    }

    // VIVO通道注册
    if(config.vivoPushAppId != null && config.vivoPushAppKey != null) {
      VivoRegister.register(context);
    }

  }

  private static void initPushVersion(Context context,String channelId,String channelName,String channelDescription) {
//    GcmRegister.register(this, "851061211440", "api-8646462459812937352-2848");
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationManager mNotificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
      // 通知渠道的id
      String id = channelId;
      // 用户可以看到的通知渠道的名字.
      CharSequence name = channelName;
      // 用户可以看到的通知渠道的描述
      String description = channelDescription;
      int importance = NotificationManager.IMPORTANCE_HIGH;
      NotificationChannel mChannel = new NotificationChannel(id, name, importance);
      // 配置通知渠道的属性
      mChannel.setDescription(description);
      // 设置通知出现时的闪灯（如果 android 设备支持的话）
      mChannel.enableLights(true);
      mChannel.setLightColor(Color.RED);
      // 设置通知出现时的震动（如果 android 设备支持的话）
      mChannel.enableVibration(true);
      mChannel.setVibrationPattern(new long[]{100, 200, 300, 400, 500, 400, 300, 200, 400});
      //最后在notificationmanager中创建该通知渠道
      mNotificationManager.createNotificationChannel(mChannel);
    }
  }



  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    FlutterAliyunPushPlugin.isPluginAttached = true;
    EventBus.getDefault().register(this);
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    Log.i(TAG, "onDetachedFromEngine");
    FlutterAliyunPushPlugin.isPluginAttached = false;
    EventBus.getDefault().unregister(this);
    aliyunPushPluginChannel.setMethodCallHandler(null);
    aliyunPushPluginChannel = null;
  }


  public void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
    synchronized (initializationLock) {
      if (aliyunPushPluginChannel != null) {
        return;
      }

      Log.i(TAG, "onAttachedToEngine");

      aliyunPushPluginChannel =
              new MethodChannel(
                      messenger, CHANNEL_NAME, StandardMethodCodec.INSTANCE);

      // Instantiate a new Plugin and connect the primary method channel for
      // Android/Flutter communication.
      aliyunPushPluginChannel.setMethodCallHandler(this);

      dealCacheEvent();

//      aliyunPushPluginChannel.invokeMethod("onPushInit",null);

    }
  }

  private void dealCacheEvent() {
    if(!FlutterAliyunPushPlugin.isFlutterHasListened) {
      //等待，直到dart有监听了执行
      new Handler().postDelayed(new Runnable() {
        @Override
        public void run() {
          dealCacheEvent();
        }
      },1000);
      return;
    }

    if(lastPushRegistSuccessMessage != null) {
      Log.i(TAG, "invokeMethod:"+ "onPushRegistSuccess");
      aliyunPushPluginChannel.invokeMethod("onPushRegistSuccess",lastPushRegistSuccessMessage);
      lastPushRegistSuccessMessage = null;
    }else if(lastPushRegistErrorMessage != null) {
      Log.i(TAG, "invokeMethod:"+ "onPushRegistError");
      aliyunPushPluginChannel.invokeMethod("onPushRegistError",lastPushRegistErrorMessage);
      lastPushRegistErrorMessage = null;
    }

    dealOfflineMessage();
  }

  private void dealOfflineMessage() {
    //传递缓存的消息到dart
    if(cachedNotifications.size() > 0) {
      Log.i(TAG, "invokeMethod cachedNotifications");
      for (FlutterPushNotification message : cachedNotifications) {
        aliyunPushPluginChannel.invokeMethod(PushMessageEvent.EVENT_onReceiverNotification,message.getParamsJSONString());
      }
      cachedNotifications.clear();
    }

    if(cachedMessages.size() > 0) {
      Log.i(TAG, "invokeMethod cachedMessages");
      for (FlutterPushMessage message : cachedMessages) {
        aliyunPushPluginChannel.invokeMethod(PushMessageEvent.EVENT_onReceiverNotification,message.getParamsJSONString());
      }
      cachedMessages.clear();
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    Log.i(TAG, "onMethodCall:"+call.method);
    String method = call.method;
    Object arguments = call.arguments;
    try {
      if (method.equals("getPlatformVersion")) {
        // This message is sent when the Dart side of this plugin is told to initialize.
        result.success("Android " + android.os.Build.VERSION.RELEASE);
      }else if(method.equals("listened")) {
        isFlutterHasListened = true;
      }
      else {
        result.notImplemented();
      }
    } catch (Exception e) {
      result.error("error", "AlarmManager error: " + e.getMessage(), null);
    }
  }


}
