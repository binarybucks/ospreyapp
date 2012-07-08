#import <Foundation/Foundation.h>
#import <Growl/Growl.h>

@interface OSPNotificationController : NSObject <GrowlApplicationBridgeDelegate>
+ (void)growlNotificationFromString:(NSString*)string withTitle:(NSString*)title boundToUserBareJid:(NSString*)userJidForCallback;
+ (void)growlNotificationFromMessage:(XMPPMessage*)message boundToUser:(OSPUserStorageObject*)userForCallback;

@end
