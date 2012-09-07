#import "OSPChatViewController.h"
#import "NSColor+HexAdditions.h"
#import "Types.h"
#import "XMPPMessage+XEP_0224.h"
#import "OSPMessageTableCellView.h"
#import "XMPPMessage+XEP_0085.h"

typedef enum {
    localToRemote = 1, 
    remoteToLocal = 2,
} EDirection;

@interface OSPChatViewController (PrivateAPI) 
- (NSImage*) _avatarForJid:(XMPPJID*)jid;
- (void) _writeToTextView:(NSString*)message forJid:(XMPPJID*)jid;
- (void) _displayPresenceMessage:(XMPPPresence*)presence;
- (void) _displayAttentionMessage:(XMPPMessage*)message;
- (void) _displayChatMessage:(XMPPMessage*)message;

@end


@implementation OSPChatViewController

#pragma mark -  Accessors
- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

- (OSPRosterController *)rosterController
{
	return [[NSApp delegate] rosterController];
}

- (XMPPRoster *)xmppRoster
{
	return [[NSApp delegate] xmppRosterModule];
}

- (OSPRosterStorage *)xmppRosterStorage
{
	return [[NSApp delegate] xmppRosterStorage];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

//- (void)dealloc {
//    [inputField removeDelegate:self];
//}

#pragma mark - Intialization
- (void) setArrayControllerFetchPredicate {
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(bareJidStr == %@) AND (streamBareJidStr == %@)", remoteJid.bare, [[[[NSApp delegate] xmppStream] myJID] bare]];
    [arrayController setFetchPredicate:fetchPredicate];
}


- (void) setArrayControllerFilterPredicate {
    

}


- (id)initWithRemoteJid:(XMPPJID*)rjid
{
    self = [super initWithNibName:@"chatView" bundle:nil];
    if (self) {
//        isLoadViewFinished = NO;
//        isWebViewReady = NO;
        localJid = [[self xmppStream] myJID];
        remoteJid = rjid;
//        messageQueue = [[NSMutableArray alloc] init];
        
        
        
//        processingQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
//        dispatch_suspend(processingQueue);
//        processionQueueIsSuspended = YES;
        typing = NO;
        cachedUsernames = [[NSMutableDictionary alloc] init];
         


    }
    return self;
    
}

- (void) dealloc {
    // Dispatch release is not needed when compiling for Mac OS X >= 10.8
    #if MAC_OS_X_VERSION_MIN_REQUIRED < 1080
    dispatch_release(processingQueue);
    #endif
}

- (void) awakeFromNib {
    [self setArrayControllerFetchPredicate];
    [self setArrayControllerFilterPredicate];
    
    [inputField bind:@"hidden" toObject:[[NSApp delegate] connectionController] withKeyPath:@"connectionState" options:[NSDictionary dictionaryWithObjectsAndKeys:@"OSPConnectionStateToNotAuthenticatedTransformer",NSValueTransformerNameBindingOption, nil]];
    
}



- (void)cstmviewWillLoad {
    
}

- (void)cstmviewDidLoad {
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"chat" withExtension:@"html"];
//	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

//- (void)loadView {
//    if (!isLoadViewFinished) {
//        [self cstmviewWillLoad];
//        [super loadView];
//        [self cstmviewDidLoad];
//        isLoadViewFinished = YES;
//    }
//}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
//    isWebViewReady = YES;
//    // There is no way to know if a queue is suspended and suspending a already suspended queue crashes 
//    if (processionQueueIsSuspended) {
//        dispatch_resume(processingQueue);
//        processionQueueIsSuspended = NO;
//    }
}

- (void)scrollToBottom:sender;
{
    NSPoint newScrollOrigin;
    
    // assume that the scrollview is an existing variable
    if ([[scrollView documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollView documentView] frame])
                                    -NSHeight([[scrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    }
    
    [[scrollView documentView] scrollPoint:newScrollOrigin];
    
}








- (void) focusInputField {
    [inputField becomeFirstResponder];
}




# pragma mark - Message display 

// Convenience accessors to processing queue
//- (void) displayChatMessage:(XMPPMessage*)message {
//    [self dispatch:message toSelector:@selector(_displayChatMessage:)];
//
//}
//- (void) displayAttentionMessage:(XMPPMessage*)message {
//    [self dispatch:message toSelector:@selector(_displayAttentionMessage:)];
//
//}
//- (void) displayPresenceMessage:(XMPPPresence*)message {
//    [self dispatch:message toSelector:@selector(_displayPresenceMessage:)];
//     
//}
//
//// Processing queue scheduler
//- (void) dispatch:(NSXMLElement*)object toSelector:(SEL)selector {
//    dispatch_block_t block = ^{ @autoreleasepool {
//        //    if ([self respondsToSelector:selector]) {
//            dispatch_async(dispatch_get_main_queue(), ^{  
//                [self tryToPerform:selector with:object];
//            });
//        }
//    };
//	
//	if (isWebViewReady == YES) {  block(); } 
//    else { self.loadView; dispatch_async(processingQueue, block); }    
//}
//
//// Private methods for actual display. 
// Never call from outside as corresponding webView might not be ready.
- (void) _displayChatMessage:(XMPPMessage*)message {
//    XMPPJID *fromJID = [[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]] bareJID]; 
//    DOMHTMLElement *messageElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
//
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"HH:mm:ss"];
//    
//    DOMHTMLElement *datetime = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"span"];
//    [datetime setAttribute:@"class" value:@"datetime"];
//    [datetime setInnerText:[formatter stringFromDate:[NSDate date]]];
//    
//    // Check if we have an inbound or outbound message
//    NSString *inOut = [fromJID isEqualToJID:remoteJid] ? @"in" : @"out";
//    
//    
//    // Check if message is in a streak
//    if ((![fromJID isEqualToJID:lastMessageFromJid]) || (streakElement == nil)) {
//        streakElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
//        [streakElement setAttribute:@"class" value:[NSString stringWithFormat:@"streak %@", inOut]]; 
//        [[[[webView mainFrame] DOMDocument] getElementById:@"chat"] appendChild:streakElement];
//    }
//    
//    [messageElement setAttribute:@"class" value:[NSString stringWithFormat:@"message %@", inOut]];    
//    [messageElement setInnerHTML:[NSString stringWithFormat:@"%@", [[message elementForName:@"body"] stringValue]]];
//    [messageElement appendChild:datetime];
//    lastMessageFromJid = fromJID;
//    
//    [streakElement appendChild:messageElement];
//    [messageElement scrollIntoView:YES];
    
}

//- (void) _displayAttentionMessage:(XMPPMessage*)message {
//    DOMHTMLElement *messageElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
//
//    streakElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
//    [streakElement setAttribute:@"class" value:@"streak attention"]; 
//    [[[[webView mainFrame] DOMDocument] getElementById:@"chat"] appendChild:streakElement];
//    
//    [messageElement setAttribute:@"class" value:[NSString stringWithFormat:@"message"]];    
//    [messageElement setInnerHTML:[NSString stringWithFormat:@"Your contact %@", [[message elementForName:@"body"] stringValue]]];
//
//    lastMessageFromJid = nil;
//
//    [streakElement appendChild:messageElement];
//    [messageElement scrollIntoView:YES];
//}
//
//- (void) _displayPresenceMessage:(XMPPPresence*)presence {
//    
//}

// Takes input from the user, sends it and enques for display
- (IBAction) send:(id)sender {
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addActiveChatState];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];

    [body setStringValue:[sender stringValue]];
    [message addChild:body];
    
    [[self xmppStream] sendElement:message];
    [message addAttributeWithName:@"from" stringValue:[localJid full]];
    
//    [self displayChatMessage:message];
    
    [sender setStringValue:@""];
}



- (NSImage*) _avatarForJid:(XMPPJID*)jid {
    OSPUserStorageObject *user = [[self xmppRosterStorage] userForJID:jid xmppStream:[self xmppStream] managedObjectContext:[self managedObjectContext]];
    
    NSImage *avatar;
    
    assert(user); // Not sure if the own user is always contained in the roster
    
    // If the photo is cached in the roster, use that, otherwise get it from vCardAvatarModule
    if (user.photo != nil)
	{
		avatar = user.photo;
	} 
	else
	{
        NSData *photoData = [[[NSApp delegate] xmppvCardAvatarModule] photoDataForJID:jid];
        if (photoData != nil) {
            avatar = [[NSImage alloc] initWithData:photoData];
            user.photo = avatar; // Cache it in roster while we're at it
        } else { 
            avatar = [NSImage imageNamed:@"Account"];
        }
    }
    
    [avatar setSize:NSMakeSize(38.0, 38.0)];
    return avatar;
}


/*!
 * @brief Starts a timer for typing notification when the user starts entering text in the input field
 */
- (void)controlTextDidBeginEditing:(NSNotification *)notification{    
    [self sendChatStateComposing];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(userStopedTyping) userInfo:nil repeats:NO];
    typing = YES;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    OSPMessageTableCellView *view = nil;
    XMPPMessageArchiving_Message_CoreDataObject *item = [[arrayController arrangedObjects] objectAtIndex:row];
    BOOL isLastInStreak = [self isLastInStreak:row tableView:tableView item:item];
    
    

    
    

    if ([item isOutgoing]) {
                if (isLastInStreak && (row != [tableView numberOfRows]-1)) {
                    view = [tableView makeViewWithIdentifier:@"lastOutgoingMessageCellView" owner:self];
                } else {
                    view = [tableView makeViewWithIdentifier:@"outgoingMessageCellView" owner:self];
                }

    } else {
        if (isLastInStreak  && (row != [tableView numberOfRows]-1)) {
            view = [tableView makeViewWithIdentifier:@"lastIncommingMessageCellView" owner:self];
        } else {
            view = [tableView makeViewWithIdentifier:@"incommingMessageCellView" owner:self];
        }
    }
    return view;
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    OSPMessageTableRowView *rowView = nil;
//    
////    BOOL isFirstInStreak = [self isNewStreak:row];
//    XMPPMessageArchiving_Message_CoreDataObject *item = [[arrayController arrangedObjects] objectAtIndex:row];
//
//    BOOL isLastInStreak = [self isLastInStreak:row tableView:tableView item:item];
//
//    
//    
//    if ([item isOutgoing]) {
//        if (isLastInStreak) {
//            rowView = [[OSPOutgoingMessageTableRowView alloc] init];
//        } else {
//            rowView = [[OSPFirstOutgoingMessageTableRowView alloc] init];
//        }
//    } else {
//        if (isLastInStreak) {
//            rowView = [[OSPIncommingMessageTableRowView alloc] init];
//        } else {
//            rowView = [[OSPFirstIncommingMessageTableRowView alloc] init];
//        }
//    }
//    return rowView;
//
//}

- (BOOL)isLastInStreak:(NSInteger)row tableView:(NSTableView*)tableView item:(XMPPMessageArchiving_Message_CoreDataObject *)item{
    if (row == [tableView numberOfRows]-1) {
        return YES;
    }
    
    XMPPMessageArchiving_Message_CoreDataObject *nextItem = [[arrayController arrangedObjects] objectAtIndex:row+1];
    
    BOOL currentRowOutgoing = item.isOutgoing;
    BOOL nextRowOutgoing = nextItem.isOutgoing;
    
    if ((currentRowOutgoing && nextRowOutgoing) || (!currentRowOutgoing && !nextRowOutgoing)) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isFirstInStreak:(NSInteger)row{
    if (row == 0) {
        return YES;
    }
    
    XMPPMessageArchiving_Message_CoreDataObject *item = [[arrayController arrangedObjects] objectAtIndex:row];
    XMPPMessageArchiving_Message_CoreDataObject *previousItem = [[arrayController arrangedObjects] objectAtIndex:row-1];

    BOOL currentRowOutgoing = item.isOutgoing;
    BOOL previousRowOutgoing = previousItem.isOutgoing;

    if ((currentRowOutgoing && previousRowOutgoing) || (!currentRowOutgoing && !previousRowOutgoing)) {
        return NO;
    } else {
        return YES;
    }
}

- (NSString*)cachedUsernameForJid:(XMPPJID*)jid {
    
    NSString *username = [cachedUsernames valueForKey:jid.bare];
    if (username == nil) {
        OSPUserStorageObject *user = [[self xmppRosterStorage] userForJID:jid xmppStream:[self xmppStream] managedObjectContext:[self managedObjectContext]];

        username = user.displayName;
    
        [cachedUsernames setValue:username forKey:jid.bare];
    }
    NSLog(@"name: %@", username);
    return username;
}

//- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
//    
////    BOOL previousRowIsOutgoing = NO;
////    BOOL currentRowIsOutgoing;
////    BOOL nextRowIsOutgoing = NO;
//////NSInteger rows = [tableView numberOfRows]-1;
////    
//////
////    currentRowIsOutgoing = [((XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row]) isOutgoing];
//////    
//////    // Check if we're last
////    if (row < rows) {
////        nextRowIsOutgoing = [((XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row+1]) isOutgoing];
////    }
////    
////    if (row > 0) {
////        previousRowIsOutgoing = [((XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row-1]) isOutgoing];
////    }
////
////    if ((currentRowIsOutgoing && nextRowIsOutgoing && previousRowIsOutgoing) || (!currentRowIsOutgoing && !nextRowIsOutgoing && !previousRowIsOutgoing)) {
////        // in a streak
////        return 25.0;
////    } else if ((currentRowIsOutgoing && !nextRowIsOutgoing && !previousRowIsOutgoing) || (!currentRowIsOutgoing && nextRowIsOutgoing && previousRowIsOutgoing)){
////        // one between two 
////        return 60.0;
////    } else {
////        // first or last in streak
////        return 40.0;
////    }
////    return 45.0;
//}


/*!
 * @brief Refreshes timer when new text is entered,  resends typing notification ajd refreshes timer when user restarts typing
 */
- (void)controlTextDidChange:(NSNotification *)notification {
    if (!typing) {
        [self sendChatStateComposing];
        typing = YES;
    }
    
    [inputTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(userStopedTyping) userInfo:nil repeats:NO];
}

/*!
 * @brief Sends active state when timer expires. Sending paused state would make more sense, but most clients support just active and typing states 
 */
- (void) userStopedTyping {
    [self sendChatStateActive];
    typing = NO;
}

- (void)sendChatStateActive {
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addActiveChatState];
    [[self xmppStream] sendElement:message];
}

- (void)sendChatStateComposing {
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addComposingChatState];
    [[self xmppStream] sendElement:message];
}




@end
