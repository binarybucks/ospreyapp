#import "OSPChatController.h"
#import "OSPRosterTableCellView.h"
#import "XMPPPresence+NiceShow.h"
#import "XMPPMessage+XEP_0224.h"
#import "NSManagedObjectContext+EasyFetching.h"

@interface OSPChatController (PrivateApi)
- (void)_threadsaveXmppRosterDidChange:(NSNotification *)notification;
- (OSPChatViewController*) chatViewControllerForJidStr:(NSString*)jidStr;
- (void) _setArrayControllerFilterPredicate;
- (void)_incrementUnreadCounterForUserIfNeccessary:(OSPUserStorageObject*)user;
- (void)_clearUnreadCounterForUser:(OSPUserStorageObject*)user;
- (void)_setBadgeLabelToCurrentSummedUnreadCount;

- (NSArray*) allChatStorageObjectsForXmppStream:(XMPPStream*)stream;
- (OSPChatCoreDataStorageObject*) chatStorageObjectForXmppStream:(XMPPStream*)stream jid:(XMPPJID *)jid;
- (void) rosterStorageMainThreadManagedObjectContextDidMergeChanges;
- (OSPChatCoreDataStorageObject*)persistOpenChatWithJid:(NSString*)jidStr;
-(void)makeChatViewControllerActive:(OSPChatViewController*)cvc ;
- (void) _setArrayControllerFetchPredicate;
@end

/*!
 * @class OSPChatController
 * @brief Handles opening, closing and messaging of active chats
 *
 * This class controlls handling of open chats, allocation of chatViewControllers and routing of incomming messages
 * to their corresponding chatViewController where they will be displayed.
 */
@implementation OSPChatController
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

- (OSPChatStorageObject*)selectedChat {
	return [[openChatsArrayController selectedObjects] objectAtIndex:0];
}

#pragma mark - Initialization
- (id)init {
	self = [super init];
	if (self) {
		initialAwakeFromNibCallFinished = NO;
		openChatViewControllers = [[NSMutableDictionary alloc] init];
		openChatsStorage = [[OSPChatCoreDataStorage alloc] init];
		openChatsMoc = [openChatsStorage mainThreadManagedObjectContext];
	}
	return self;
}

- (void) awakeFromNib {
	if (!initialAwakeFromNibCallFinished) {
        
		[[self xmppRoster] addDelegate:self delegateQueue:dispatch_get_main_queue()];
		[[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
		[[[NSApp delegate] xmppAttentionModule] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [self _setArrayControllerFetchPredicate];
		[self _setArrayControllerFilterPredicate];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rosterStorageMainThreadManagedObjectContextDidMergeChanges)
                                                     name:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(chatStorageMainThreadManagedObjectContextDidMergeChanges:)
                                                     name:@"chatStorageMainThreadManagedObjectContextDidMergeChanges"
                                                   object:nil];
        
		summedUnreadCount = 0;
		initialAwakeFromNibCallFinished = YES;
	}
}



- (void) _setArrayControllerFetchPredicate {
    // No need to fetch more than neccessary. TODO: Call when jid changes
    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
    DDLogVerbose(@"FETCHING ROSTER WITH %@", jid); 
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@", jid];
    
    [openChatsArrayController setFetchPredicate:fetchPredicate];
}


- (void) _setArrayControllerFilterPredicate {
    /*
     * Uppon disconnect the RosterStorage urges it's storage to start clean on future connects (not really sure why)
     * Thus, uppon disconnect we might have ChatStorageObjects without UserStorageObjects shown in the GUI. 
     * We filter them out until there is an UserStorageObject associated with them, hence the userStorageObject != nil
     * TODO: Call when jid changes
     */
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"userStorageObject != nil"];
    [openChatsArrayController setFilterPredicate:fetchPredicate];

    }


/*!
 * Brief: Tells every ChatStorageObject for the current XMPPStream to refetch its UserStorageObject
 */
- (void) rosterStorageMainThreadManagedObjectContextDidMergeChanges {
    // TODO: Just refetch updated UserStorageObjects
    
    for (OSPChatStorageObject *chatStorageObject in [self allChatStorageObjectsForXmppStream:[self xmppStream]]) {
        [chatStorageObject refetchUserStorageObject];
    }
}

- (void)chatStorageMainThreadManagedObjectContextDidMergeChanges {
    // Nothing to be done here and not notification not send yet
}


# pragma mark - Chat Opening
/*!
 * @brief Used to open new chats from a UserStorageObject from the roster
 */
- (void)openChatWithUser:(OSPUserStorageObject*)user andMakeActive:(BOOL)makeActive{
	// Save that we have an open chat with that user
	OSPChatStorageObject *chatStorageObject = [self persistOpenChatWithJid:user.jidStr];
    
	// Get ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:user.jidStr];
    
	if (makeActive) {
		[self makeChatViewControllerActive:cvc];
        NSLog(@"arraycontroller objects: %@" , [openChatsArrayController arrangedObjects]);
		[openChatsArrayController setSelectedObjects:@[chatStorageObject]];
	}
}

/*!
 * @brief Used to open chats from a jidStr.
 */
- (void)openChatWithJidStr:(NSString*)jidStr andMakeActive:(BOOL)makeActive{
	// Save that we have an open chat with that jid
	OSPChatStorageObject *chatStorageObject = [self persistOpenChatWithJid:jidStr];
    
	// Get ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:jidStr];
	if (makeActive) {
		[self makeChatViewControllerActive:cvc];
        [openChatsArrayController setSelectedObjects:@[chatStorageObject]];
	}
}

/*!
 * @brief Used to open existing chats from a ChatStorageObject
 */
- (void)openChatWithStoredChat:(OSPChatCoreDataStorageObject*)storedChat andMakeActive:(BOOL)makeActive{
	// There is no need to persist the opened chat here, as we already have a ChatStorageObject
    
	// Get ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:storedChat.jidStr];
	if (makeActive) {
		[self makeChatViewControllerActive:cvc];
        [openChatsArrayController setSelectedObjects:@[storedChat]];
    }
}

/*!
 * @brief Fetches or creates a ChatStorageObject from JidStr to save an open chat
 */
- (OSPChatCoreDataStorageObject*)persistOpenChatWithJid:(NSString*)jidStr {
	DDLogVerbose(@"Persisting open chat with jidStr %@", jidStr);
    
	OSPChatCoreDataStorageObject *storedChat = [self chatStorageObjectForXmppStream:[self xmppStream] jidStr:jidStr];
    
	if (storedChat == nil) {
		DDLogVerbose(@"No previous ChatStorageObject found, saving a new one for jidStr %@", jidStr);
		OSPChatCoreDataStorageObject *chatObject = [NSEntityDescription insertNewObjectForEntityForName:@"OSPChatCoreDataStorageObject" inManagedObjectContext:openChatsMoc];
        
        
		chatObject.jidStr = jidStr;
		chatObject.streamBareJidStr = [[[self xmppStream] myJID] bare];
		NSError *error = nil;
		[openChatsMoc save:&error];
		if (error != nil) {
			NSLog(@"Error saving ChatStorageObject for %@. Error was: %@", jidStr, [error description]);
			storedChat = nil;
		}
        // Without this, the arrayController takes ages to show the objecs
        [openChatsMoc processPendingChanges]; 
        [openChatsArrayController rearrangeObjects];
        
        storedChat = chatObject;
	}
    
	return storedChat;
}

/*!
 * Brief: Lazyloads ChatViewController for a JidStr
 */
- (OSPChatViewController*) chatViewControllerForJidStr:(NSString*)jidStr {
    LOGFUNCTIONCALL
	if (jidStr == nil) {
		DDLogError(@"Error, trying to open chat with empty jid");
		return nil;
	}
    
	DDLogVerbose(@"ChatViewController for %@ was requested", jidStr);
    
	OSPChatViewController *cvc = [openChatViewControllers valueForKey:jidStr];
	if (cvc == nil) {
		DDLogVerbose(@"Allocating new ChatViewController for %@", jidStr);
		cvc = [[OSPChatViewController alloc] initWithRemoteJid:[XMPPJID jidWithString:jidStr]];
		[openChatViewControllers setValue:cvc forKey:jidStr];
	}
    
	return cvc;
}

/*!
 * @brief Shows the view of a ChatViewController in the ChatView and focuses it's input field
 */
-(void)makeChatViewControllerActive:(OSPChatViewController*)cvc {
	NSView * targetView = [cvc view];
	[targetView setFrame:[chatView bounds]];
	[targetView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
	if ([[chatView subviews] count] != 0)
		[[[chatView subviews] objectAtIndex:0] removeFromSuperview];
    
	[chatView setFrame:[targetView frame]];
	[chatView addSubview:targetView];
    
	[cvc focusInputField];
}

/*!
 * @brief Closes an open chat and selects the next one in the list of open chats
 */
- (void)closeChat:(OSPChatCoreDataStorageObject*)chat {
	LOGFUNCTIONCALL
	NSInteger selectedRow = [openChatsTable selectedRow]+1; //starts at 0
	NSInteger numberOfRows = [openChatsTable numberOfRows]; // starts at 1
    
	[openChatViewControllers removeObjectForKey:chat.jidStr];

	[openChatsArrayController removeObject:chat];
    [openChatsMoc deleteObject:chat];
    NSError *error = nil;
    [openChatsMoc save:&error];
    if (error != nil) {
        NSLog(@"Error saving removal of ChatStorageObject. Error was: %@", [error description]);
    }
    [openChatsMoc processPendingChanges];
    [openChatsArrayController rearrangeObjects];
    
	if ([[chatView subviews] count] != 0)
		[[[chatView subviews] objectAtIndex:0] removeFromSuperview];
 //Now handled correctly by OpenChatsArrayController
	if (((numberOfRows-1) > 0) && (selectedRow != numberOfRows)) { // select previous if at end
[openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-1] byExtendingSelection:NO];
       // [openChatsArrayController selectPrevious:nil];
	} else if ((numberOfRows-1 > 0) && (selectedRow == numberOfRows)) { // select next if not at end
[openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-2] byExtendingSelection:NO];
        //[openChatsArrayController selectNext:nil];
	}
}

/*!
 * @brief Triggered when the user clicks on row other than the currently selected one to change chats (CAUTION: also when table is reloaded)
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([openChatsTable numberOfSelectedRows] > 0 && [NSApp isActive]) {
		[self openChatWithStoredChat:openChatsArrayController.selectedObjects.lastObject
					   andMakeActive:YES];
	}
}

#pragma mark - Message handling
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
    OSPUserStorageObject *user = [[self xmppRosterStorage] userForJID:[message from] xmppStream:[self xmppStream] managedObjectContext:[self rosterManagedObjectContext]];
	
    [self openChatWithUser:user andMakeActive:NO]; // lazyloads ChatViewController and 
	[[openChatViewControllers valueForKey:user.jidStr] displayChatMessage:message];
    
//[self _incrementUnreadCounterForUserIfNeccessary:user];
    [OSPNotificationController notificationForIncommingMessage:message fromUser:user];
}

// Attention messages
//- (void) handleAttentionMessage:(XMPPMessage*)message {
//    OSPUserStorageObject *user = [self contactWithJid:[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]]];
//    OSPChatViewController *cvc = [self _chatViewControllerForUser:user];
//
//    [cvc displayAttentionMessage:message];
//
//    [self _incrementUnreadCounterForUserIfNeccessary:user];
//    [OSPNotificationController growlNotificationForIncommingAttentionRequest:message fromUser:user];
//}

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
    
    //    [self handleAttentionMessage:message];
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
		[self closeChat:[self selectedChat]];
	}
}






















# pragma mark - Storage accessors
- (NSArray*) allChatStorageObjectsForXmppStream:(XMPPStream*)stream {
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(streamBareJidStr = %@)", [self xmppStream].myJID.bare] ;
    
    NSArray *array = [openChatsMoc fetchEntity:@"OSPChatCoreDataStorageObject"
                            withSortDescriptor:nil
                                    fetchLimit:0
                                     predicate:predicate];
	return array;
}

- (OSPChatCoreDataStorageObject*) chatStorageObjectForXmppStream:(XMPPStream*)stream jidStr:(NSString *)jidStr{
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(streamBareJidStr = %@) AND (jidStr = %@)", [self xmppStream].myJID.bare, jidStr];
    
    NSArray *array = [openChatsMoc fetchEntity:@"OSPChatCoreDataStorageObject"
                            withSortDescriptor:nil
                                    fetchLimit:1
                                     predicate:predicate];
    
    OSPChatCoreDataStorageObject* result = [array lastObject];
    return result;
}
@end