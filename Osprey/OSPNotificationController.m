#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"

@implementation OSPNotificationController

# pragma mark - Init
- (id) init {
    self = [super init];
    if (self) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:(id)self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification object:nil];
        
        sheetCallbacks =
        @{
        @"showAccountPreferencesCallback" : ^{DDLogVerbose(@"CALLBACK: Showing account preferences");     [[[NSApp delegate] preferencesController] changePanesProgramatically:1];
            [[[[NSApp delegate] preferencesController] window] makeKeyAndOrderFront:nil];},
        @"reconnectCallback" : ^{DDLogVerbose(@"CALLBACK: Reconnecting");  [[[NSApp delegate] connectionController] connect:nil];},
            @"cancelCallback" : ^{DDLogVerbose(@"CALLBACK: Cancel");},
        };
        
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
- (void)notificationForUnsetAccountPreferences {

    NSDictionary *callbackIdentifiersForReturnCode = @{
        @"NSAlertDefaultReturn" : @"showAccountPreferencesCallback",
        @"NSAlertAlternateReturn" : @"cancelCallback"
    };
    
    [self beginAlertSheet:@"Incomplete Account Details"
                     text:@"Your account details seem to be missing some required details."
       defaultButtonLabel:@"Edit Account"
     alternateButtonLabel:@"Cancel"
         otherButtonLabel:nil
      callBackIdentifiers:callbackIdentifiersForReturnCode];
}




- (void)notificationForConnectionErrorWithErrorString:(NSString*)errorStr {
    
    NSDictionary *callbackIdentifiersForReturnCode = @{
    @"NSAlertDefaultReturn" : @"reconnectCallback",
    @"NSAlertAlternateReturn" : @"cancelCallback",
    @"NSAlertOtherReturn" : @"showAccountPreferencesCallback"
    };
    
    [self beginAlertSheet:@"Connection Error"
                     text:errorStr
       defaultButtonLabel:@"Reconnect"
     alternateButtonLabel:@"Cancel"
         otherButtonLabel:@"Edit Account"
      callBackIdentifiers:callbackIdentifiersForReturnCode];
}


- (void)notificationForAuthenticationErrorWithErrorString:(NSString*)errorStr {
    
    NSDictionary *callbackIdentifiersForReturnCode = @{
    @"NSAlertDefaultReturn" : @"reconnectCallback",
    @"NSAlertAlternateReturn" : @"cancelCallback",
    @"NSAlertOtherReturn" : @"showAccountPreferencesCallback"
    };
    
    [self beginAlertSheet:@"Authentication Error"
                     text:errorStr
       defaultButtonLabel:@"Reconnect"
     alternateButtonLabel:@"Cancel"
         otherButtonLabel:@"Edit Account"
      callBackIdentifiers:callbackIdentifiersForReturnCode];
}


/*!
 * @brief Convenience wrapper for showing an alert sheet
 */
- (void)beginAlertSheet:(NSString*)title text:(NSString*)text defaultButtonLabel:(NSString*)defaultButtonLabel alternateButtonLabel:(NSString*)alternateButtonLabel otherButtonLabel:(NSString*)otherButtonLabel callBackIdentifiers:(NSDictionary*)callbackIdentifiers {
    
    NSBeginAlertSheet( title, defaultButtonLabel, alternateButtonLabel, otherButtonLabel,  window, self, @selector(sheetClosed:returnCode:contextInfo:), NULL, (__bridge_retained void *)(callbackIdentifiers), text, nil);
}

/*!
 * @brief Generic selector for sheet callbacks
 * Takes a NSDictionary as context info that contains the numeric values of NSAlertDefaultReturn, NSAlertAlternateReturn and NSAlertOtherReturn in string format as keys and showAccountPreferences keys as values. Thus, if you want to reconnect on NSAlertDefaultReturn, pass in @{[NSString stringWithFormat:@"%d", NSAlertAlternateReturn]: @"reconnect"} as context info
 */
- (void)sheetClosed:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *callbackIdentifiersForReturnCode = (__bridge_transfer NSDictionary*) contextInfo;
    NSString *callbackIdentifier; // Default callback
    
    if (returnCode == NSAlertDefaultReturn) {
        callbackIdentifier = [callbackIdentifiersForReturnCode valueForKey:@"NSAlertDefaultReturn"];
    } else if (returnCode == NSAlertAlternateReturn) {
        callbackIdentifier = [callbackIdentifiersForReturnCode valueForKey:@"NSAlertAlternateReturn"];
    } else if (returnCode == NSAlertOtherReturn) {
        callbackIdentifier = [callbackIdentifiersForReturnCode valueForKey:@"NSAlertOtherReturn"];
    }
    
    void (^callbackBlock)() = (void (^)())[sheetCallbacks valueForKey:callbackIdentifier];
    if (callbackBlock) {
        callbackBlock();
    } else {
        DDLogError(@"No callback block associated with return code");
    };
}

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

#pragma mark - Application activation handling

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self clearAllNotificationsOfChat:[[self chatController] activeChat]];
}


@end
