#import <Foundation/Foundation.h>

@interface OSPNotificationController : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

+ (void)notificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;
+ (void)notificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;
- (void) removeAllNotifications;
@end
