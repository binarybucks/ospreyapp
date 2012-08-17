#import <Foundation/Foundation.h>

@interface OSPNotificationController : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate> {
    IBOutlet NSWindow *window;
}

- (void)notificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;
- (void)notificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;
- (void)notificationForConnectionErrorWithErrorString:(NSString*)errorStr;
- (void)notificationForAuthenticationErrorWithErrorString:(NSString*)errorStr;

- (void)removeAllNotificationCenterNotifications;


@end
