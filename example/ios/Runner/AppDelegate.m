#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <flutter_aliyun_push/FlutterAliyunPushPlugin.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [FlutterAliyunPushPlugin initKey:@"333354905" appSecret:@"eeb5f0e8b09442b29b64658a0c5fa9b7"];
    
    [GeneratedPluginRegistrant registerWithRegistry:self];

    
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

/*
 *  APNs注册成功回调，将返回的deviceToken上传到CloudPush服务器
 */
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
//    NSLog(@"appdelegate didRegisterForRemoteNotificationsWithDeviceToken ---");
//    [FlutterAliyunPushPlugin application:application
//        didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
//}

/*
 *  APNs注册失败回调
 */
//- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
//    NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
//}


/*
 *  App处于启动状态时，通知打开回调
 */
//- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
//    NSLog(@"didReceiveRemoteNotification------- Receive one notification.");
////    [FlutterAliyunPushPlugin application:application didReceiveRemoteNotification:userInfo];
//
//}

#pragma mark 禁止横屏
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

@end
