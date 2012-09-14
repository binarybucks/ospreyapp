#import "OSPChatController.h"
#import "OSPRosterTableCellView.h"
#import "XMPPPresence+NiceShow.h"
#import "XMPPMessage+XEP_0224.h"
#import "NSManagedObjectContext+EasyFetching.h"
#import "XMPPMessage+XEP_0085.h"

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
	return [[NSApp delegate] xmppRosterModule];
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

- (OSPNotificationController*)notificationController {
    return [[NSApp delegate] notificationController];
}

// deprecated
- (OSPChatStorageObject*)selectedChat {
	return [[openChatsArrayController selectedObjects] objectAtIndex:0];
}

- (OSPChatStorageObject*)activeChat {
    return activeChat;
}

- (BOOL)isActiveChat:(OSPChatStorageObject*)chat {
    return [chat isEqualTo:activeChat];
}

#pragma mark - Initialization
- (id)init {
	self = [super init];
	if (self) {
		initialAwakeFromNibCallFinished = NO;
		openChatViewControllers = [[NSMutableDictionary alloc] init];
		openChatsStorage = [[OSPChatCoreDataStorage alloc] init];
		openChatsMoc = [openChatsStorage mainThreadManagedObjectContext];
        activeChat = nil;
	}
	return self;
}

- (void) awakeFromNib {
	if (!initialAwakeFromNibCallFinished) {
        
		[[self xmppRoster] addDelegate:self delegateQueue:dispatch_get_main_queue()];
		[[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [self setArrayControllerFetchPredicate];
		[self setArrayControllerFilterPredicate];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rosterStorageMainThreadManagedObjectContextDidMergeChanges)
                                                     name:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(chatStorageMainThreadManagedObjectContextDidMergeChanges)
                                                     name:@"chatStorageMainThreadManagedObjectContextDidMergeChanges"
                                                   object:nil];
        
		summedUnreadCount = 0;
		initialAwakeFromNibCallFinished = YES;
	}
}

//- (void)loadView {
//    [self myViewWillLoad];
//    [super loadView];
//    [self myViewDidLoad];
//}
//
//- (void)myViewWillLoad {
//}
//
//- (void)myViewDidLoad {
//
//}

- (void) setArrayControllerFetchPredicate {
    /*
     * No need to fetch more than neccessary.
     * TODO: Call when jid changes
     */
    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@", jid];
    [openChatsArrayController setFetchPredicate:fetchPredicate];
}


- (void) setArrayControllerFilterPredicate {
    /*
     * Uppon disconnect the RosterStorage purges it's storage to start clean on future connects (not really sure why)
     * Thus, uppon disconnect we might have ChatStorageObjects without UserStorageObjects shown in the GUI. 
     * We filter them out until there is an UserStorageObject associated with them, hence the userStorageObject != nil
     * TODO: Call when jid changes
     */
//    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"userStorageObject != nil"];
//    [openChatsArrayController setFilterPredicate:fetchPredicate];
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
    // Nothing to be done here. Notification not send yet
}


# pragma mark - Chat Opening
/*!
 * @brief Used to open new chats from a UserStorageObject from the roster. Returns OSPChatStorageObject for convenience
 */
- (OSPChatStorageObject*)openChatWithUser:(OSPUserStorageObject*)user andMakeActive:(BOOL)makeActive{
	// Save that we have an open chat with that user
	OSPChatStorageObject *chatStorageObject = [self persistOpenChatWithJid:user.jidStr];
    
	// Get and lazyload ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:user.jidStr];
    
	if (makeActive) {
        [self activateChat:chatStorageObject withChatViewController:cvc];
	}
    return chatStorageObject;
}

/*!
 * @brief Used to open chats from a jidStr. Returns OSPChatStorageObject for convenience 
 */
- (OSPChatStorageObject*)openChatWithJidStr:(NSString*)jidStr andMakeActive:(BOOL)makeActive{
	// Save that we have an open chat with that jid
	OSPChatStorageObject *chatStorageObject = [self persistOpenChatWithJid:jidStr];
    
	// Get and lazyload ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:jidStr];
	if (makeActive) {
        [self activateChat:chatStorageObject withChatViewController:cvc];
	}
    return chatStorageObject;
}

/*!
 * @brief Used to open existing chats from a ChatStorageObject
 */
- (void)openChatWithStoredChat:(OSPChatCoreDataStorageObject*)chatStorageObject andMakeActive:(BOOL)makeActive{
	// There is no need to persist the opened chat here, as we already have a ChatStorageObject
    
	// Get and lazyload ChatViewController
	OSPChatViewController *cvc = [self chatViewControllerForJidStr:chatStorageObject.jidStr];
	if (makeActive) {
        [self activateChat:chatStorageObject withChatViewController:cvc];
    }
}

- (void)activateChat:(OSPChatStorageObject*)chatStorageObject withChatViewController:(OSPChatViewController*)cvc {
    [[self notificationController] clearAllNotificationsOfChat:chatStorageObject];
    [self activateChatViewController:cvc];
    [openChatsArrayController setSelectedObjects:@[chatStorageObject]];
    activeChat = chatStorageObject; // Prevents rapid reselection in nstableview:selectionDidChange
    
}


/*!
 * @brief Fetches or creates a ChatStorageObject from JidStr to save an open chat
 */
- (OSPChatStorageObject*)persistOpenChatWithJid:(NSString*)jidStr {
	DDLogVerbose(@"ChatStorageObject requested for %@", jidStr);
    
	OSPChatStorageObject *storedChat = [self chatStorageObjectForXmppStream:[self xmppStream] jidStr:jidStr];
    
	if (storedChat == nil) {
		DDLogVerbose(@"ChatStorageObject not found. Creating new");
		OSPChatCoreDataStorageObject *chatObject = [NSEntityDescription insertNewObjectForEntityForName:@"OSPChatCoreDataStorageObject" inManagedObjectContext:openChatsMoc];
        
        
		chatObject.jidStr = jidStr;
		chatObject.streamBareJidStr = [[[self xmppStream] myJID] bare];
        chatObject.type = [NSNumber numberWithInt:singleChat];
        
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
	} else {
        DDLogVerbose(@"ChatStorageObject found");

    }
    
	return storedChat;
}

/*!
 * Brief: Lazyloads ChatViewController for a JidStr
 */
- (OSPChatViewController*) chatViewControllerForJidStr:(NSString*)jidStr {
	if (jidStr == nil) {
		DDLogError(@"Error, trying to open chat with empty jid");
		return nil;
	}
    
	DDLogVerbose(@"ChatViewController requested for %@", jidStr);
    
	OSPChatViewController *cvc = [openChatViewControllers valueForKey:jidStr];
	if (cvc == nil) {
		DDLogVerbose(@"ChatViewController not found. Creating new");
		cvc = [[OSPChatViewController alloc] initWithRemoteJid:[XMPPJID jidWithString:jidStr]];
		[openChatViewControllers setValue:cvc forKey:jidStr];
	} else {
        DDLogVerbose(@"ChatViewController found");
    }
    
	return cvc;
}

/*!
 * @brief Shows the view of a ChatViewController in the ChatView and focuses it's input fi®eld
 */
-(void)activateChatViewController:(OSPChatViewController*)cvc {
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
    
    if ([self isActiveChat:chat]) {
        activeChat = nil;
    }
    
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
	if (((numberOfRows-1) > 0) && (selectedRow != numberOfRows)) { // select previous if at end
        [openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-1] byExtendingSelection:NO];
	} else if ((numberOfRows-1 > 0) && (selectedRow == numberOfRows)) { // select next if not at end
        [openChatsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow-2] byExtendingSelection:NO];
	}
    
}

- (IBAction)closeSelectedChat:(id)sender{
	if ([openChatsTable selectedRow] >= 0) {
		[self closeChat:[self selectedChat]];
	}
}

/*!
 * @brief Triggered when the user clicks on row other than the currently selected one to change chats (CAUTION: also when table is reloaded)
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	OSPChatStorageObject *chat = [self selectedChat];
    if (![self isActiveChat:chat]) { // No need to activate an already active chat
		[self openChatWithStoredChat:chat
					   andMakeActive:YES];
	}
}


#pragma mark - Message handling
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message isChatMessageWithBody])
	{
        OSPChatStorageObject *chat = [self openChatWithJidStr:[[message from] bare] andMakeActive:NO];
        [chat setValue:[NSNumber numberWithBool:NO] forKey:@"isTyping"];
        [[self notificationController] notificationForIncommingMessage:message fromSingleChat:chat]; // Displays all neccessary notifications for that message
	} else {
        if ([message isActiveChatState]) {
            OSPChatStorageObject *chat = [self chatStorageObjectForXmppStream:[self xmppStream] jidStr:message.from.bare];
            [chat setValue:[NSNumber numberWithBool:NO] forKey:@"isTyping"];
        } else if ([message isComposingChatState]) {
            OSPChatStorageObject *chat = [self chatStorageObjectForXmppStream:[self xmppStream] jidStr:message.from.bare];
            [chat setValue:[NSNumber numberWithBool:YES] forKey:@"isTyping"];
        }
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