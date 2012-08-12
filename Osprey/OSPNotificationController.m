#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"

#define RECEIVED_CHAT_MESSAGE_NOTIFICATION_NAME @"incommingChatMessage"
#define RECEIVED_CHAT_MESSAGE_HUMAN_READABLE @"Incomming chat message"

#define RECEIVED_ATTENTION_REQUEST_NOTIFICATION_NAME @"incommingAttentionRequest"
#define RECEIVED_ATTENTION_REQUEST_HUMAN_READABLE @"Incomming attention request"


@implementation OSPNotificationController

# pragma mark - Init
- (id) init {
    self = [super init];
    if (self) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:(id)self];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(removeAllNotifications) name:NSApplicationDidBecomeActiveNotification object:nil];

    }
    return self;
}

+ (void)notificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    userNotification.title = user.displayName;
    userNotification.informativeText = [[message elementForName:@"body"] stringValue];
    userNotification.userInfo = @{ @"jidStr": user.jidStr, @"type" : @"incommingSingleChat"};
    userNotification.soundName = NSUserNotificationDefaultSoundName;
    userNotification.hasActionButton = YES;
    userNotification.actionButtonTitle = @"Reply";
    
    //Scheldule our NSUserNotification
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
    
}

+ (void)notificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    
    userNotification.title = user.displayName;
    userNotification.informativeText = @"wants your attention!";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

}

- (void) removeAllNotifications {
    DDLogVerbose(@"Removing all notifications");
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    DDLogVerbose(@"User clicked on notification: %@", [notification userInfo]);
    
    if ([[notification.userInfo valueForKey:@"type"] isEqualToString:@"incommingSingleChat"]) {
        [[[NSApp delegate] chatController] openChatWithJidStr:[notification.userInfo valueForKey:@"jidStr"] andMakeActive:YES];
    }
}

@end
