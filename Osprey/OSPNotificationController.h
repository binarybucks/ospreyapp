#import <Foundation/Foundation.h>

@interface OSPNotificationController : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate> {
    IBOutlet NSWindow *window;
    int badgeCount;
    NSDictionary *sheetCallbacks;
}

- (void)notificationForIncommingMessage:(XMPPMessage*)message fromSingleChat:(OSPChatStorageObject*)chat;
- (void)notificationForIncommingMessage:(XMPPMessage*)message fromSingleChat:(OSPChatStorageObject*)chat isChatSelected:(BOOL)isChatSelected;


- (void)notificationForUnsetAccountPreferences;

- (void)notificationForConnectionErrorWithErrorString:(NSString*)errorStr;
- (void)notificationForAuthenticationErrorWithErrorString:(NSString*)errorStr;
- (void)notificationForError:(EErrorState)errorState withErrorString:(NSString*)errorString;

- (void)clearAllNotificationsOfChat:(OSPChatStorageObject*)chat;

- (void)incrementBadgeCount;
- (void)decrementBadgeCount;
- (void)decrementBadgeCountBy:(int)number;
- (void)clearBadgeCount;

@end
