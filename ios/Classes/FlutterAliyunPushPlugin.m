#import "FlutterAliyunPushPlugin.h"
#import <CloudPushSDK/CloudPushSDK.h>
// iOS 10 notification
#import <UserNotifications/UserNotifications.h>
#import <Flutter/Flutter.h>

NSString * AliyunAppKey = @"";
NSString * AliyunAppSecret = @"";

const static NSString * onPushRegistSuccess = @"onPushRegistSuccess";
const static NSString * onPushRegistError = @"onPushRegistError";
const static NSString * onReceiverNotification = @"onReceiverNotification";
const static NSString * onReceiverMessage = @"onReceiverMessage";

@implementation FlutterAliyunPushPlugin {
    NSDictionary *_launchNotification;
}

+(void)initKey:(NSString *) appkey appSecret:(NSString *) appSecret {
    AliyunAppKey = appkey;
    AliyunAppSecret = appSecret;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"aliyun_push"
            binaryMessenger:[registrar messenger]];

    FlutterAliyunPushPlugin* instance = [[FlutterAliyunPushPlugin alloc] init];
    instance.channel = channel;
    
   
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}




-(void) callFlutter:(NSString *)eventName withDatas:(id _Nullable) datas {
    if(_channel == nil) {
        return;
    }
    
    [_channel invokeMethod:eventName arguments:datas];
    
}
 


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
      
  } else {
    result(FlutterMethodNotImplemented);
  }
}



/**
 初始化推送
 */
-(void) initPush:(UIApplication *)application
    launchOptions:(NSDictionary *)launchOptions  {
    
    
    // APNs注册，获取deviceToken并上报
    [self registerAPNS:application];
    // 初始化SDK
    [self initCloudPush:AliyunAppKey appSecret:AliyunAppSecret];
    
    // 监听推送通道打开动作
    [self listenerOnChannelOpened];
    
    // 监听推送消息到达
    [self registerMessageReceive];
    
    
    // 点击通知将App从关闭状态启动时，将通知打开回执上报
    [CloudPushSDK sendNotificationAck:launchOptions];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"plugin didRegisterForRemoteNotificationsWithDeviceToken ---");
    [CloudPushSDK registerDevice:deviceToken withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"Register deviceToken success, deviceToken: %@", [CloudPushSDK getApnsDeviceToken]);
        } else {
            NSLog(@"Register deviceToken failed, error: %@", res.error);
        }
    }];
    
}


/*
 *  APNs注册失败回调
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError --- %@", error);
}

#pragma mark - AppDelegate

//- (void)applicationDidBecomeActive:(UIApplication *)application {
//    NSLog(@"FlutterAliyunPushPlugin applicationDidBecomeActive----");
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"FlutterAliyunPushPlugin didFinishLaunchingWithOptions----");
    [self initPush:application launchOptions:launchOptions];
    
    
     if (launchOptions != nil) {
        _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    }
    
    if ([launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        NSLog(@"launchOptions has Notification----");
        UILocalNotification *localNotification = [launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        NSMutableDictionary *localNotificationEvent = @{}.mutableCopy;
        localNotificationEvent[@"content"] = localNotification.alertBody;
        localNotificationEvent[@"badge"] = @(localNotification.applicationIconBadgeNumber);
        localNotificationEvent[@"extras"] = localNotification.userInfo;
        localNotificationEvent[@"fireTime"] = [NSNumber numberWithLong:[localNotification.fireDate timeIntervalSince1970] * 1000];
        localNotificationEvent[@"soundName"] = [localNotification.soundName isEqualToString:UILocalNotificationDefaultSoundName] ? @"" : localNotification.soundName;
        
        if (@available(iOS 8.2, *)) {
            localNotificationEvent[@"title"] = localNotification.alertTitle;
        }
        _launchNotification = localNotificationEvent;
    }
    //[self performSelector:@selector(addNotificationWithDateTrigger) withObject:nil afterDelay:2];
    return YES;
}


//在后台未被干掉收到消息
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"didReceiveRemoteNotification------- Receive one notification.");
    // 取得APNS通知内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    // 内容
    NSString *content = [aps valueForKey:@"alert"];
    // badge数量
    NSInteger badge = [[aps valueForKey:@"badge"] integerValue];
    // 播放声音
    NSString *sound = [aps valueForKey:@"sound"];
    // 取得Extras字段内容
    NSString *Extras = [userInfo valueForKey:@"Extras"]; //服务端中Extras字段，key是自己定义的
    NSLog(@"content = [%@], badge = [%ld], sound = [%@], Extras = [%@]",
          content, (long)badge, sound, Extras);


    [self callFlutter:onReceiverNotification withDatas:userInfo];
    
    // iOS badge 清0
    application.applicationIconBadgeNumber = 0;

    
    // 通知打开回执上报
    [CloudPushSDK sendNotificationAck:userInfo];

}


#pragma mark APNs Register
/**
 *    向APNs注册，获取deviceToken用于推送
 *
 *    @param     application
 */
- (void)registerAPNS:(UIApplication *)application {
    float systemVersionNum = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersionNum >= 10.0) {
        // iOS 10 notifications
        UNUserNotificationCenter* _notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        // 创建category，并注册到通知中心
        [self createCustomNotificationCategory];
        // 请求推送权限
        [_notificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                // granted
                NSLog(@"User authored notification.");
                // 向APNs注册，获取deviceToken
                dispatch_async(dispatch_get_main_queue(), ^{
                    [application registerForRemoteNotifications];
                });
            } else {
                // not granted
                NSLog(@"User denied notification.");
            }
        }];
    } else if (systemVersionNum >= 8.0) {
        // iOS 8 Notifications
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored"-Wdeprecated-declarations"
                [application registerUserNotificationSettings:
                 [UIUserNotificationSettings settingsForTypes:
                  (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                                   categories:nil]];
                [application registerForRemoteNotifications];
        #pragma clang diagnostic pop
            } else {
                // iOS < 8 Notifications
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored"-Wdeprecated-declarations"
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
                 (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
        #pragma clang diagnostic pop
    }
}

/**
 *  创建并注册通知category(iOS 10+)
 */
- (void)createCustomNotificationCategory {
    // 自定义`action1`和`action2`
    UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"action1" title:@"test1" options: UNNotificationActionOptionNone];
    UNNotificationAction *action2 = [UNNotificationAction actionWithIdentifier:@"action2" title:@"test2" options: UNNotificationActionOptionNone];
    // 创建id为`test_category`的category，并注册两个action到category
    // UNNotificationCategoryOptionCustomDismissAction表明可以触发通知的dismiss回调
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"test_category" actions:@[action1, action2] intentIdentifiers:@[] options:
                                        UNNotificationCategoryOptionCustomDismissAction];
    // 注册category到通知中心
    UNUserNotificationCenter* _notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [_notificationCenter setNotificationCategories:[NSSet setWithObjects:category, nil]];
}

#pragma mark SDK Init
- (void)initCloudPush:(NSString*)appkey appSecret:(NSString*)appSecret {
    NSLog(@"start initCloudPush----");
    // 正式上线建议关闭
    [CloudPushSDK turnOnDebug];
    // SDK初始化，手动输出appKey和appSecret
    [CloudPushSDK asyncInit:appkey appSecret:appSecret callback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"Push SDK init success, deviceId: %@.", [CloudPushSDK getDeviceId]);
            [self callFlutter:onPushRegistSuccess withDatas:nil];
        } else {
            NSLog(@"Push SDK init failed, error: %@", res.error);
            [_channel invokeMethod:onPushRegistError arguments:res.error];
            [self callFlutter:onPushRegistError withDatas:res.error];
        }
    }];
    
   
}

/**
 *    注册推送通道打开监听
 */
- (void)listenerOnChannelOpened {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onChannelOpened:)
                                                 name:@"CCPDidChannelConnectedSuccess"
                                               object:nil];
}

/**
 *    推送通道打开回调
 *
 *    @param     notification
 */
- (void)onChannelOpened:(NSNotification *)notification {
    NSLog(@"消息通道建立成功-----");
}

#pragma mark Receive Message
/**
 *    @brief    注册推送消息到来监听
 */
- (void)registerMessageReceive {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageReceived:)
                                                 name:@"CCPDidReceiveMessageNotification"
                                               object:nil];
}

/**
 *    处理在前台到来推送消息
 *
 *    @param     notification
 */
- (void)onMessageReceived:(NSNotification *)notification {
    NSLog(@"onMessageReceived------ Receive one message!");
   
    CCPSysMessage *message = [notification object];
    NSString *title = [[NSString alloc] initWithData:message.title encoding:NSUTF8StringEncoding];
    NSString *body = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];
    NSLog(@"Receive message title: %@, content: %@.", title, body);

    if(![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self callFlutter:onReceiverMessage withDatas:body];
        });
    } else {
        [self callFlutter:onReceiverMessage withDatas:body];
    }
}


@end
