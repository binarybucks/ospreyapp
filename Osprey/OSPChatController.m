#import "OSPChatController.h"
#import "OSPRosterTableCellView.h"
#import "XMPPPresence+NiceShow.h"
#import "XMPPMessage+XEP_0224.h"

@interface OSPChatController (PrivateApi)
- (void)_threadsaveXmppRosterDidChange:(NSNotification *)notification;
- (OSPChatViewController*) _chatViewControllerForUser:(id <XMPPUser>)user;
- (void) _setArrayControllerFilterPredicate;
- (void)_incrementUnreadCounterForUserIfNeccessary:(OSPUserStorageObject*)user;
- (void)_clearUnreadCounterForUser:(OSPUserStorageObject*)user;
- (void)_setBadgeLabelToCurrentSummedUnreadCount;
@end


@implementation OSPChatController

@synthesize openChatUsers;


#pragma mark - Convenience accessors
- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

- (XMPPRoster *)xmppRoster
{
	return [[NSApp delegate] xmppRoster];
}

- (OSPRosterStorage *)xmppRosterStorage
{
	return [[NSApp delegate] xmppRosterStorage];
}
- (OSPRosterController *)rosterController
{
	return [[NSApp delegate] rosterController];
}
- (NSManagedObjectContext* )managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

- (OSPUserStorageObject*)selectedUser {
    return [[openChatsArrayController selectedObjects] objectAtIndex:0];
}

- (OSPUserStorageObject*) contactWithJid:(XMPPJID*)jid {
    return  (OSPUserStorageObject*)[[self xmppRosterStorage] userForJID:jid
                               xmppStream:[self xmppStream]
                     managedObjectContext:[self managedObjectContext]];
}


#pragma mark - Initialization


- (void) _setArrayControllerFilterPredicate {

    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
    DDLogVerbose(@"FETCHING OPEN CHATS WITH %@", jid);
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND chatOpened != nil", jid];
    
    [openChatsArrayController setFetchPredicate:fetchPredicate];
}




- (void) awakeFromNib {
    if (!initialAwakeFromNibCallFinished) {

        [[self xmppRoster] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[[NSApp delegate] xmppAttentionModule] addDelegate:self delegateQueue:dispatch_get_main_queue()];

        [openChatsArrayController setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"chatOpened" ascending:YES]]];
        [self _setArrayControllerFilterPredicate];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setArrayControllerFilterPredicate) name:@"UserChangedJid" object:nil];
        
        summedUnreadCount = 0;
        initialAwakeFromNibCallFinished = YES; 
    }

    }

- (id)init {
    self = [super init];
    if (self) {
        initialAwakeFromNibCallFinished = NO;
        self.openChatUsers = [[NSMutableArray alloc] init];
        openChatViewControllers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

# pragma mark - Private API
- (OSPChatViewController*) _chatViewControllerForUser:(OSPUserStorageObject*)user {
    
    NSString *jid = [[user jid] bare];
    if (jid == nil)
        return;
    
    DDLogVerbose(@"ChatViewController for %@ was requested", jid);
    OSPChatViewController *cvc = [openChatViewControllers valueForKey:jid];
    if (cvc == nil) {
        DDLogVerbose(@"Allocating new ChatViewController for %@", user.jidStr);
        
        
        cvc = [[OSPChatViewController alloc] initWithRemoteJid:[user jid]];
        [openChatViewControllers setValue:cvc forKey:jid];
        [openChatsArrayController fetchWithRequest:nil merge:NO error:nil];
        [openChatsArrayController rearrangeObjects];
        
        
    }
    if ([user valueForKey:@"chatOpened"] == nil) {
        [((OSPUserStorageObject*)user) setValue:[[NSDate alloc] init] forKey:@"chatOpened"];
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            DDLogError(@"save failed");
            DDLogError(@"%@",[error description]);
        }
    }    
    DDLogVerbose(@"Returning %@ for %@", cvc, jid);
    return cvc;
}


# pragma mark - Chat Opening/Closing

- (void)openChatWithJid:(XMPPJID*)jid {    
    [self openChatWithUser:[self contactWithJid:jid]];
}

- (void)openChatWithUser:(OSPUserStorageObject*)user {    
    [self _clearUnreadCounterForUser:user];

    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    
    
    NSView * targetView = [cvc view];
    [targetView setFrame:[chatView bounds]];
    [targetView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    if ([[chatView subviews] count] != 0)
		[[[chatView subviews] objectAtIndex:0] removeFromSuperview];

	[chatView setFrame:[targetView frame]];
	[chatView addSubview:targetView];	
    
    [openChatsArrayController setSelectedObjects:[NSArray arrayWithObject:user]];
    [windowTitle setStringValue:[user displayName]];
    [cvc focusInputField];
}

- (void)closeChatWithUser:(OSPUserStorageObject*)user {
    LOGFUNCTIONCALL
    NSInteger selectedRow = [openChatsTable selectedRow]+1; //starts at 0
    NSInteger numberOfRows = [openChatsTable numberOfRows]; // starts at 1

    [openChatViewControllers removeObjectForKey:user.jid.bare];
    [((OSPUserStorageObject*)user) setValue:nil forKey:@"chatOpened"];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"save failed");
        NSLog(@"%@",[error description]);
    }
    
    
    
    [openChatsArrayController fetchWithRequest:nil merge:NO error:nil];
    [openChatsArrayController rearrangeObjects];

    if ([[chatView subviews] count] != 0)
		[[[chatView subviews] objectAtIndex:0] removeFromSuperview];
    
    // select next chat after closing if there are any open chats left
    if (((numberOfRows-1) > 0) && (selectedRow != numberOfRows)) { 
        [openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-1] byExtendingSelection:NO];
    } else if ((numberOfRows-1 > 0) && (selectedRow == numberOfRows)) { 
        [openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-2] byExtendingSelection:NO];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([openChatsTable numberOfSelectedRows] > 0) {
        [self openChatWithUser:[self selectedUser]];
    }
}



#pragma mark - Message handling



// States
- (void) handlePresence:(XMPPPresence*)presence {
    OSPChatViewController *cvc = [openChatViewControllers valueForKey:[[XMPPJID jidWithString:[presence attributeStringValueForName:@"from"]] bare]];    
    if (cvc == nil) {
        return;
    } else {
        [cvc displayPresenceMessage:presence];
    }
}

// Chat messages
- (void) handleChatMessage:(XMPPMessage*)message {
    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];        
    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    
    [cvc displayChatMessage:message];

    [self _incrementUnreadCounterForUserIfNeccessary:user];
    [OSPNotificationController growlNotificationFromMessage:message boundToUser:user];
}

// Attention messages
- (void) handleAttentionMessage:(XMPPMessage*)message {
    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];        
    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    

    
    [cvc displayAttentionMessage:message];
    
    [self _incrementUnreadCounterForUserIfNeccessary:user];
    [OSPNotificationController growlNotificationFromString:[[message elementForName:@"body"] stringValue] withTitle:user.displayName boundToUserBareJid:user.jid.bare];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isChatMessageWithBody]) 
    {
        [self handleChatMessage:message];
    } 
}

- (void)xmppAttention:(XMPPAttentionModule *)sender didReceiveAttentionHeadlineMessage:(XMPPMessage *)message {
    if (![message isAttentionMessageWithBody]) {
        [message addChild:[NSXMLElement elementWithName:@"body" stringValue:@"wants your attention!"]];
    }
    
    [self handleAttentionMessage:message];
}



















//- (void) handleReceivedMessage:(XMPPMessage*)message {
//    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];        
//    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    
//    [cvc receive:message];
//}
//
//- (void) handleReceivedAttentioneMessage:(XMPPMessage*)message {
//    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];        
//    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    
//    
//    if (![message isAttentionMessageWithBody])
//    
//    [cvc receive:message];
//    
//    [self _incrementUnreadCounterForUserIfNeccessary:user];
//    [OSPNotificationController displayNotificationForAttentionMessage:message fromUser:user];
//}
//
//

//



- (void)_incrementUnreadCounterForUserIfNeccessary:(OSPUserStorageObject*)user {
    BOOL userIsSelected = openChatsArrayController.selectedObjects.lastObject == user;
    BOOL windowsIsKeyWindow = [[[NSApp delegate] window] isKeyWindow];
    
    if (!userIsSelected || !windowsIsKeyWindow) {
        [user setValue:[NSNumber numberWithInt:([[user unreadMessages] intValue] + 1)] forKey:@"unreadMessages"];
        summedUnreadCount++;
        [self _setBadgeLabelToCurrentSummedUnreadCount];
    }
    

    
}
- (void)_clearUnreadCounterForUser:(OSPUserStorageObject*)user {
    if (!user.unreadMessages) {
        return;
    }
    
    NSNumber *userUnreadCount = user.unreadMessages;
    summedUnreadCount -= [userUnreadCount intValue];
    [user setValue:[NSNumber numberWithInt:0] forKey:@"unreadMessages"];
    
    [self _setBadgeLabelToCurrentSummedUnreadCount];
}

- (void)_setBadgeLabelToCurrentSummedUnreadCount {
    if (summedUnreadCount == 0) {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
    } else {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d", summedUnreadCount]];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self _clearUnreadCounterForUser:openChatsArrayController.selectedObjects.lastObject];
}

# pragma mark - Navigation
- (IBAction)closeSelectedChat:(id)sender{
    if ([openChatsTable selectedRow] >= 0) {        
        [self closeChatWithUser:[self selectedUser]];
    }
}

@end