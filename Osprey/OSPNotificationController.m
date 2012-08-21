#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"

@implementation OSPNotificationController

# pragma mark - Init
- (id) init {
    self = [super init];
    if (self) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:(id)self];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(removeAllNotifcationCenterNotifications) name:NSApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}


# pragma mark - Notification Center Notifications
- (void)notificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
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

- (void)notificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    
    userNotification.title = user.displayName;
    userNotification.informativeText = @"wants your attention!";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

}

- (void) removeAllNotifcationCenterNotifications {
//    DDLogVerbose(@"Removing all notifications");
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    DDLogVerbose(@"User clicked on notification: %@", [notification userInfo]);
    
    if ([[notification.userInfo valueForKey:@"type"] isEqualToString:@"incommingSingleChat"]) {
        [[[NSApp delegate] chatController] openChatWithJidStr:[notification.userInfo valueForKey:@"jidStr"] andMakeActive:YES];
    }
}

# pragma mark - Error Notifications

- (void)notificationForConnectionErrorWithErrorString:(NSString*)errorStr {
    [self notificationForError:connectionError withErrorString:errorStr];
}

- (void)notificationForAuthenticationErrorWithErrorString:(NSString*)errorStr {
    [self notificationForError:authenticationError withErrorString:errorStr];
}

- (void)notificationForError:(EErrorState)errorState withErrorString:(NSString*)errorString {
    SEL sel = @selector(errorSheetClosed:returnCode:contextInfo:);
    NSString *errorTitle;
    
    switch (errorState) {
        case connectionError:
            errorTitle = @"Connection Error";
            break;
        case authenticationError:
            errorTitle = @"Authentication Error";
            break;
        default:
            DDLogError(@"Notification for error type not implemented yet");
            return;
    }
    
    NSBeginAlertSheet(errorTitle, @"Reconnect", @"Check account", @"Cancel", window, self, sel, NULL, nil, errorString, nil);

}

- (void)errorSheetClosed:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) { // Reconnect
        [[[NSApp delegate] connectionController] performSelector:@selector(connect:) withObject:nil afterDelay:0.5]; 
    } else if (returnCode == NSAlertAlternateReturn) { // Check Account
        [[[NSApp delegate] preferencesController] changePanesProgramatically:1];
        [[[[NSApp delegate] preferencesController] window] makeKeyAndOrderFront:nil];
    } else if (returnCode == NSAlertOtherReturn) { // Cancel
        [[[NSApp delegate] connectionController] performSelector:@selector(disconnect:) withObject:nil afterDelay:0.5];     }
}

# pragma mark - Application Badge Notifications

- (void) incrementBadgeCount {
    
}

- (void) clearBadgeCount {
    
}

- (void) decrementBadgeCountBy:(NSNumber*)number {
    
}

@end
