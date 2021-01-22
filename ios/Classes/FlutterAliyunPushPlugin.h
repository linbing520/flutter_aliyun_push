#import <Flutter/Flutter.h>

@interface FlutterAliyunPushPlugin : NSObject<FlutterPlugin>

extern NSString * AliyunAppKey;
extern NSString * AliyunAppSecret;

@property (nonatomic, strong) FlutterMethodChannel *channel;

+(void)initKey:(NSString *) appkey appSecret:(NSString *) appSecret ;


@end
