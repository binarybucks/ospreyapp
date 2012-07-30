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

- (NSArray *)fetchEntity:(NSString*)entityName managedObjectContext:(NSManagedObjectContext*)moc sortDescriptor:(NSSortDescriptor*)sortDescriptor fetchLimit:(NSInteger)fetchLimit predicate:(id)stringOrPredicate, ...;
- (NSArray*) allChatStorageObjectsForXmppStream:(XMPPStream*)stream;
- (OSPChatCoreDataStorageObject*) chatStorageObjectForXmppStream:(XMPPStream*)stream jid:(XMPPJID *)jid;
- (void) rosterStorageMainThreadManagedObjectContextDidMergeChanges;
@end


@implementation OSPChatController

@synthesize openChatUsers;
@synthesize openChatsMoc;

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
- (NSManagedObjectContext* )rosterManagedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

- (OSPUserStorageObject*)selectedUser {
    //return [[openChatsArrayController selectedObjects] objectAtIndex:0];
    return nil;
}

- (OSPUserStorageObject*) contactWithJid:(XMPPJID*)jid {
//    return  (OSPUserStorageObject*)[[self xmppRosterStorage] userForJID:jid
//                               xmppStream:[self xmppStream]
//                     managedObjectContext:[self rosterManagedObjectContext]];
    return nil;
}


#pragma mark - Initialization

//
//- (void) _setArrayControllerFilterPredicate {
//
//    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
//    DDLogVerbose(@"Fetching open chats for jid %@", jid);
//    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND chatOpened != nil", jid];
//    
//    [openChatsArrayController setFetchPredicate:fetchPredicate];
//}




- (void) awakeFromNib {
    if (!initialAwakeFromNibCallFinished) {

        [[self xmppRoster] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[[NSApp delegate] xmppAttentionModule] addDelegate:self delegateQueue:dispatch_get_main_queue()];
//
//        [[NSNotificationCenter defaultCenter] addObserver:self 
//                                                 selector:@selector(chatStorageMainThreadManagedObjectContextDidMergeChanges:)
//                                                     name:@"chatStorageMainThreadManagedObjectContextDidMergeChanges"
//                                                   object:nil];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self 
//                                                 selector:@selector(rosterStorageMainThreadManagedObjectContextDidMergeChanges:)
//                                                     name:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges"
//                                                   object:nil];
        summedUnreadCount = 0;
        initialAwakeFromNibCallFinished = YES; 
//        [self chatStorageMainThreadManagedObjectContextDidMergeChanges]; // fetch chats
    }
}



//- (void)chatStorageMainThreadManagedObjectContextDidMergeChanges {
//    openChats = [self allChatStorageObjectsForXmppStream:[self xmppStream]];
//    [openChatsTable reloadData];
//}


- (id)init {
    self = [super init];
    if (self) {
        initialAwakeFromNibCallFinished = NO;
        self.openChatUsers = [[NSMutableArray alloc] init];
        openChatViewControllers = [[NSMutableDictionary alloc] init];
        openChats = [[NSArray alloc] init];
        openChatsStorage = [[OSPChatCoreDataStorage alloc] init]; 
        openChatsMoc = [openChatsStorage mainThreadManagedObjectContext];
    }
    return self;
}


// Lazyloads chatViewController
- (OSPChatViewController*) chatViewControllerForUser:(OSPUserStorageObject*)user {
    
    NSString *jid = [[user jid] bare];
    if (jid == nil) {
        DDLogError(@"Error, trying to open chat with empty jid");
        return nil;
    }
    DDLogVerbose(@"ChatViewController for %@ was requested", jid);
    
    OSPChatViewController *cvc = [openChatViewControllers valueForKey:jid];
    if (cvc == nil) {
        DDLogVerbose(@"Allocating new ChatViewController for %@", user.jidStr);
        cvc = [[OSPChatViewController alloc] initWithRemoteJid:[user jid]];
        [openChatViewControllers setValue:cvc forKey:jid];
        OSPChatCoreDataStorageObject *chatObject = [NSEntityDescription insertNewObjectForEntityForName:@"OSPChatCoreDataStorageObject" inManagedObjectContext:openChatsMoc];
        chatObject.jid = jid;
        chatObject.streamBareJidStr = [[[self xmppStream] myJID] bare];
        NSError *error;
        [openChatsMoc save:&error];
        if (error != nil) {
            NSLog(@"Error saving: %@", [error description]);
        }
    }
    
    
    
    return cvc;
}

// Loads persistent chatStorageObject from store
- (OSPChatCoreDataStorageObject*) chatStorageObjectForUser:(OSPUserStorageObject*)user {
    return [self chatStorageObjectForXmppStream:[self xmppStream] jid:user.jid];
}

# pragma mark - Chat Opening/Closing
- (void)openChatWithJid:(XMPPJID*)jid {    
    [self openChatWithUser:[self contactWithJid:jid]];
}


- (void)openChatWithUser:(OSPUserStorageObject*)user {    
    OSPChatViewController *cvc = [self chatViewControllerForUser:user];    
    
    NSView * targetView = [cvc view];
    [targetView setFrame:[chatView bounds]];
    [targetView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    if ([[chatView subviews] count] != 0)
		[[[chatView subviews] objectAtIndex:0] removeFromSuperview];

	[chatView setFrame:[targetView frame]];
	[chatView addSubview:targetView];	
    
    [cvc focusInputField];
}

- (void)closeChatWithUser:(OSPUserStorageObject*)user {
    LOGFUNCTIONCALL
    NSInteger selectedRow = [openChatsTable selectedRow]+1; //starts at 0
    NSInteger numberOfRows = [openChatsTable numberOfRows]; // starts at 1

    [openChatViewControllers removeObjectForKey:user.jid.bare];

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
    if ([openChatsTable numberOfSelectedRows] > 0 && [NSApp isActive]) {
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
    [OSPNotificationController growlNotificationForIncommingMessage:message fromUser:user];
}

// Attention messages
- (void) handleAttentionMessage:(XMPPMessage*)message {
    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];        
    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];    

    [cvc displayAttentionMessage:message];
    
    [self _incrementUnreadCounterForUserIfNeccessary:user];
    [OSPNotificationController growlNotificationForIncommingAttentionRequest:message fromUser:user];
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

- (void)_incrementUnreadCounterForUserIfNeccessary:(OSPUserStorageObject*)user {
//    BOOL userIsSelected = openChatsArrayController.selectedObjects.lastObject == user;
    BOOL userIsSelected = YES;

    BOOL windowsIsKeyWindow = [[[NSApp delegate] window] isKeyWindow];
    
    if (!userIsSelected || !windowsIsKeyWindow) {
//        [user setValue:[NSNumber numberWithInt:([[user unreadMessages] intValue] + 1)] forKey:@"unreadMessages"];
//         [[self xmppRosterStorage] setValue:[NSNumber numberWithInt:([[user unreadMessages] intValue] + 1)] forKeyPath:@"unreadMessages" forUserWithJid:user.jid onStream:[self xmppStream]];
//        NSError *error = nil;
//        if (![self.rosterManagedObjectContext save:&error]) {
//            DDLogError(@"ManagedObjectContext save failed");
//            DDLogError(@"%@",[error description]);
//        }    
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
//    [user setValue:[NSNumber numberWithInt:0] forKey:@"unreadMessages"];
//    [[self xmppRosterStorage] setValue:[NSNumber numberWithInt:0] forKeyPath:@"unreadMessages" forUserWithJid:user.jid onStream:[self xmppStream]];
    
    [self _setBadgeLabelToCurrentSummedUnreadCount];
}

- (void)_setBadgeLabelToCurrentSummedUnreadCount {
    if (summedUnreadCount <= 0) {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
        summedUnreadCount = 0; // set to 0 in case we hit a negative number
    } else {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d", summedUnreadCount]];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
//    [self _clearUnreadCounterForUser:openChatsArrayController.selectedObjects.lastObject];
}

# pragma mark - Navigation
- (IBAction)closeSelectedChat:(id)sender{
    if ([openChatsTable selectedRow] >= 0) {        
        [self closeChatWithUser:[self selectedUser]];
    }
}






















# pragma mark - Storage accessors
- (NSArray*) allChatStorageObjectsForXmppStream:(XMPPStream*)stream {

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"streamBareJidStr = %@", [[openChatsStorage myJIDForXMPPStream:stream] bare]];
    NSArray *array = [self fetchEntity:@"OSPChatCoreDataStorageObject" 
                                        managedObjectContext:openChatsMoc 
                                              sortDescriptor:nil
                                                  fetchLimit:nil
                                                   predicate:predicate];
    return array;
}

- (OSPChatCoreDataStorageObject*) chatStorageObjectForXmppStream:(XMPPStream*)stream jid:(XMPPJID *)jid{
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(streamBareJidStr = %@) AND (@jid = %@)", [[openChatsStorage myJIDForXMPPStream:stream] bare], [jid bare]];
    NSArray *array = [self fetchEntity:@"OSPChatCoreDataStorageObject" 
                                        managedObjectContext:openChatsMoc 
                                              sortDescriptor:nil
                                                  fetchLimit:1
                                                   predicate:predicate];
    
    return (OSPChatCoreDataStorageObject*)[array lastObject];
}

- (NSArray *)fetchEntity:(NSString*)entityName managedObjectContext:(NSManagedObjectContext*)moc sortDescriptor:(NSSortDescriptor*)sortDescriptor fetchLimit:(NSInteger)fetchLimit predicate:(id)stringOrPredicate, ...
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    if (stringOrPredicate) {
        NSPredicate *predicate;
        if ([stringOrPredicate isKindOfClass:[NSString class]]) {
            va_list variadicArguments;
            va_start(variadicArguments, stringOrPredicate);
            predicate = [NSPredicate predicateWithFormat:stringOrPredicate arguments:variadicArguments];
            va_end(variadicArguments);
        } else {
            NSAssert2([stringOrPredicate isKindOfClass:[NSPredicate class]], @"Second parameter passed to %s is of unexpected class %@", sel_getName(_cmd), [stringOrPredicate className]);
            predicate = (NSPredicate *)stringOrPredicate;
        }
        [request setPredicate:predicate];
    }
    if (sortDescriptor != nil) {
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }
    if (sortDescriptor != nil) {
        [request setFetchLimit:fetchLimit];
    }
    NSError *error = nil;
    NSArray *results = [openChatsMoc executeFetchRequest:request error:&error];
    if (error != nil) {
        [NSException raise:NSGenericException format:[error description]];
    }
    
    return results;
}








@end