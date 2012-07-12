#import <Foundation/Foundation.h>
#import <Growl/Growl.h>

@interface OSPNotificationController : NSObject <GrowlApplicationBridgeDelegate>

+ (void)growlNotificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;
+ (void)growlNotificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user;

+ (void) genericGrowlNotification:(NSString *)title
                      description:(NSString *)description
                 notificationName:(NSString *)notifName
                         iconData:(NSData *)iconData
                         priority:(signed int)priority
                         isSticky:(BOOL)isSticky
                     clickContext:(id)clickContext;


@end
