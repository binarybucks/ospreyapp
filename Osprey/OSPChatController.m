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
#import "XMPPUserCoreDataStorageObject+NotSubscribed.h"

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
                                                 selector:@selector(setArrayControllerFetchPredicate)
                                                     name:@"UserChangedJid"
                                                   object:nil];
        
        
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
    DDLogVerbose(@"rosterStorageMainThreadManagedObjectContextDidMergeChanges");
    // TODO: Just refetch updated UserStorageObjects
    
    for (OSPChatStorageObject *chatStorageObject in [self allChatStorageObjectsForXmppStream:[self xmppStream]]) {
        [chatStorageObject refetchUserStorageObject];
    }
    [openChatsTable reloadData];
}

#pragma mark - Chat object display 

- (NSView *)tableView:(NSTableView *)aTableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    // This method isn't a beauty. TODO: Refactor
    
    OSPRosterTableCellView *view = [aTableView makeViewWithIdentifier:@"RosterTableCellView" owner:self];;
    
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:row];

    OSPUserStorageObject *user = chat.userStorageObject;

    NSString *username;
    NSString *status;

    if (user) {
        username = user.displayName;
        
        if (![[[NSApp delegate] xmppStream] isAuthenticated]) {
            status = @"Offline";
        } else if (user.isPendingApproval) {
            status = @"Pending approval";
        } else if (user.isNotSubscribed) {
            status = @"Not subscribed";
        } else if (chat.isTyping == [NSNumber numberWithBool:YES]) {
            status = @"Typing...";
            
        } else if (user.primaryResource == nil) {
            status = @"Offline";
        } else {
            
            switch (user.primaryResource.intShow)
            {
                case 3:
                    status = @"Online";
                    break;
                case 2:
                    status = @"Away";
                    break;
                case 0:
                    status = @"Do not distrub";
                    break;
                case 1:
                    status = @"Extended away";
                    break;
                case 4:
                    status = @"Free for chat";
                    break;
                default:
                    status = @"Unknown";
            }
        }
    }
    else    // User is not in our roster or we don't have a roster yet
    {
        username = chat.jidStr;
        status = @"Not in roster";
    }
    
    view.textField.stringValue = username;
    view.statusTextfield.stringValue = status;

    return view;
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
			DDLogError(@"Error saving ChatStorageObject for %@. Error was: %@", jidStr, [error description]);
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
        DDLogError(@"Error saving removal of ChatStorageObject. Error was: %@", [error description]);
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



/*!
 * @brief Prepares the context menu for a chat 
 */
- (void)menuNeedsUpdate:(NSMenu *)menu {
    LOGFUNCTIONCALL
    NSInteger clickedRow = [openChatsTable clickedRow];

    // Just display menu when clicked on an item
    if (!(clickedRow >= 0 && clickedRow < [openChatsTable numberOfRows])) {
        return;
    }
    
    // Prepare data
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:clickedRow];
    OSPUserStorageObject *user = [[self xmppRosterStorage] userForJID:[XMPPJID jidWithString:chat.jidStr] xmppStream:[self xmppStream] managedObjectContext:[self rosterManagedObjectContext]];
    
    
    
    // Item 1
    [[menu itemAtIndex:0] setTitle:[NSString stringWithFormat:@"Jid: %@", [chat jidStr]]];
    [[menu itemAtIndex:0] setEnabled:NO];

    NSNumber *type = [chat type];
    
    switch ([type intValue]) {
        case singleChat:
            [[menu itemAtIndex:1] setTitle:@"Type: Single chat"];
            break;
        case multiChat:
            [[menu itemAtIndex:1] setTitle:@"Type: Group chat"];

        default:
            break;
    }
    [[menu itemAtIndex:1] setEnabled:NO];
    
    // Item 2
    if (user != nil) {
        [[menu itemAtIndex:2] setTitle:[NSString stringWithFormat:@"Subscription: %@", user.subscription]];
        
        [[menu itemAtIndex:3] setTitle:[NSString stringWithFormat:@"Ask: %@", user.ask]];

        // + Divider
        
        [[menu itemAtIndex:5] setTitle:@"Remove from roster"];
        [[menu itemAtIndex:5] setAction:@selector(removeFromRoster)];
        [[menu itemAtIndex:5] setEnabled:YES];
        
        
        if (([user.subscription isEqualToString:@"both"]) || ([user.subscription isEqualToString:@"to" ])) {
            [[menu itemAtIndex:6] setTitle:@"Unsubscribe from presence"];
            [[menu itemAtIndex:6] setEnabled:YES];
            [[menu itemAtIndex:6] setAction:@selector(unsubscribe)];

        } else {
            [[menu itemAtIndex:6] setTitle:@"Subscribe to presence"];
            [[menu itemAtIndex:6] setEnabled:YES];
            [[menu itemAtIndex:6] setAction:@selector(subscribe)];

        }
        
        
    } else {
        [[menu itemAtIndex:2] setTitle:@"Subscription: Unknown"];
        [[menu itemAtIndex:3] setTitle:@"Ask: Unknown"];
        
        // + Divider
        
        [[menu itemAtIndex:5] setTitle:@"Add to roster"];
        [[menu itemAtIndex:5] setAction:@selector(addToRoster)];
        [[menu itemAtIndex:5] setEnabled:YES];


    }
    

    
    if (([user.subscription isEqualToString:@"both"]) || ([user.subscription isEqualToString:@"from" ])) {
        [[menu itemAtIndex:7] setTitle:@"Block"];
        [[menu itemAtIndex:7] setEnabled:YES];
        [[menu itemAtIndex:7] setAction:@selector(block)];
        [[menu itemAtIndex:7] setHidden:NO];
    } else {
        [[menu itemAtIndex:7] setHidden:YES];
    }



    

}

- (void)removeFromRoster {
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:[openChatsTable  clickedRow]];

    DDLogVerbose(@"removing %@", chat.jidStr);
    
    [[self xmppRoster] removeUser:[XMPPJID jidWithString:chat.jidStr]];
}


- (void)addToRoster {
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:[openChatsTable  clickedRow]];

    [[self xmppRoster] addUser:[XMPPJID jidWithString:chat.jidStr] withNickname:nil];

    DDLogVerbose(@"adding %@", chat.jidStr);
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    
}


// Cancels a subscription previously granted to a contact, thereby disabling sending of our presence to the contact.
// this is similar to forcing a Twitter contact to unfollow you
// Sends <presence to='romeo@example.net' type='unsubscribed'/>
// Note: Does not remove contact from roster
- (void)block{
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:[openChatsTable  clickedRow]];

    [[self xmppRoster] revokePresencePermissionFromUser:[XMPPJID jidWithString:chat.jidStr]];
}

// Unsubscribes from presence updates send by a contact
// Sends <presence to='juliet@example.com' type='unsubscribe'/>
- (void)unsubscribe {
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:[openChatsTable  clickedRow]];
    
    [[self xmppRoster] unsubscribePresenceFromUser:[XMPPJID jidWithString:chat.jidStr]];
}


// Sends a presence subscription request to the contact
// <presence to='juliet@example.com' type='subscribe'/>

// Contact answers with:
// <presence to='romeo@example.net' type='subscribed'/> to accept
// or
// <presence to='romeo@example.net' type='unsubscribed'/> to reject the request

-(void)subscribe {
    OSPChatStorageObject *chat = [[openChatsArrayController arrangedObjects] objectAtIndex:[openChatsTable  clickedRow]];

    XMPPPresence *presence = [XMPPPresence presenceWithType:@"subscribe" to:[XMPPJID jidWithString:chat.jidStr]];
	[[self xmppStream] sendElement:presence];
	
}



@end