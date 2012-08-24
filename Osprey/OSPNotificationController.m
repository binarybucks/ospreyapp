#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"

@implementation OSPNotificationController

# pragma mark - Init
- (id) init {
    self = [super init];
    if (self) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:(id)self];
    }
    return self;
}

- (OSPChatController*) chatController {
    return [[NSApp delegate] chatController];
}

# pragma mark - Chat Message Notifications

// Convenience method. It automatically queries if the chat is selected. If you already know that, use the other method to save some ping-pong calls
- (void)notificationForIncommingMessage:(XMPPMessage*)message fromSingleChat:(OSPChatStorageObject*)chat {
    [self notificationForIncommingMessage:message fromSingleChat:chat isChatSelected:[[self chatController] isActiveChat:chat]];
}

- (void)notificationForIncommingMessage:(XMPPMessage*)message fromSingleChat:(OSPChatStorageObject*)chat isChatSelected:(BOOL)isChatSelected {
    
    /* 
     * For now, we just display any kind of notification if the app is not active or the chat of the notification is not focused.
     * TODO: Let the user choose which notifications to display when
     */
    
    if (![NSApp isActive] || !isChatSelected) {
        
        // Notification Center Notifications
        NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    
        if (chat.userStorageObject != nil) {
            userNotification.title = ((OSPUserStorageObject*)chat.userStorageObject).displayName;
        } else {
            userNotification.title = chat.jidStr;
        }

        userNotification.informativeText = [[message elementForName:@"body"] stringValue];
        userNotification.userInfo = @{ @"jidStr": chat.jidStr, @"type" : @"incommingSingleChat"};
        userNotification.soundName = NSUserNotificationDefaultSoundName;
        userNotification.hasActionButton = YES;
        userNotification.actionButtonTitle = @"Reply";
    
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
        
        
        // Application icon badge
        [self incrementBadgeCount];

        // Chat unread badge
        [self incrementUnreadCountOfChat:chat];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if ([[notification.userInfo valueForKey:@"type"] isEqualToString:@"incommingSingleChat"]) {
        
        // Note: andMakeActive:YES triggers cleaRAllNotificationsOfChat
        // It could be called directly from here, but putting the call in openChatWithJidStr makes it more versatile
        [[self chatController] openChatWithJidStr:[notification.userInfo valueForKey:@"jidStr"] andMakeActive:YES];
    }
}

// Called when a chat becomes active (Notification Center notification is clicked, chat is selected manually) 
- (void) clearAllNotificationsOfChat:(OSPChatStorageObject*)chat {
    
    [self decrementBadgeCountBy:chat.unreadCount.intValue];
    [self clearUnreadCountOfChat:chat];
    
    // Remove all Notification Center notifications for that chat.
    for (NSUserNotification *notification in [[NSUserNotificationCenter defaultUserNotificationCenter] deliveredNotifications]) {
        if ([[notification.userInfo valueForKey:@"jidStr"] isEqualToString:chat.jidStr]) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
        }
    }
}

- (void) incrementUnreadCountOfChat:(OSPChatStorageObject*)chat {
    // TODO: That call is ugly, is there any better way to simply increment a coredata number by one without reading it first?
    [chat setValue:[NSNumber numberWithInt:[[chat valueForKey:@"unreadCount"] intValue]+1] forKey:@"unreadCount"];

}

- (void) clearUnreadCountOfChat:(OSPChatStorageObject*)chat {
    [chat setValue:[NSNumber numberWithInt:0] forKey:@"unreadCount"];
}

# pragma mark - Error Notifications

- (void)notificationForConnectionErrorWithErrorString:(NSString*)errorStr {
    [self notificationForError:connectionError withErrorString:errorStr];
}

- (void)notificationForAuthenticationErrorWithErrorString:(NSString*)errorStr {
    [self notificationForError:authenticationError withErrorString:errorStr];
}

- (void)notificationForError:(EErrorState)errorState withErrorString:(NSString*)errorString {
//    SEL sel = @selector(errorSheetClosed:returnCode:contextInfo:);
//    NSString *errorTitle;
//    
//    switch (errorState) {
//        case connectionError:
//            errorTitle = @"Connection Error";
//            break;
//        case authenticationError:
//            errorTitle = @"Authentication Error";
//            break;
//        default:
//            DDLogError(@"Notification for error type not implemented yet");
//            return;
//    }
//    
//    NSBeginAlertSheet(errorTitle, @"Reconnect", @"Check account", @"Cancel", window, self, sel, NULL, nil, errorString, nil);

}

//- (void)errorSheetClosed:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//    if (returnCode == NSAlertDefaultReturn) { // Reconnect
//        [[[NSApp delegate] connectionController] performSelector:@selector(connect:) withObject:nil afterDelay:0.5]; 
//    } else if (returnCode == NSAlertAlternateReturn) { // Check Account
//        [[[NSApp delegate] preferencesController] changePanesProgramatically:1];
//        [[[[NSApp delegate] preferencesController] window] makeKeyAndOrderFront:nil];
//    } else if (returnCode == NSAlertOtherReturn) { // Cancel
//        [[[NSApp delegate] connectionController] performSelector:@selector(disconnect:) withObject:nil afterDelay:0.5];     }
//}

# pragma mark - Application Badge Notifications
- (void) incrementBadgeCount {
    badgeCount +=1;
    [self setBadgeLabel:[NSString stringWithFormat:@"%d", badgeCount]];
}

- (void) decrementBadgeCount {
    [self decrementBadgeCountBy:1];
}

- (void) clearBadgeCount {
    badgeCount = 0;
    [self setBadgeLabel:@""];
}

- (void) decrementBadgeCountBy:(int)number {
    if (badgeCount - number <= 0) {
        badgeCount = 0;
        [self setBadgeLabel:@""];
    } else {
        [self setBadgeLabel:[NSString stringWithFormat:@"%d", badgeCount]];
    }
}

- (void) setBadgeLabel:(NSString*)str {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:str];
}

@end
