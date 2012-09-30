#import "OSPChatViewController.h"
#import "OSPMessageTableCellView.h"
#import "Types.h"
#import "NSColor+HexAdditions.h"
#import "XMPPMessage+XEP_0224.h"
#import "XMPPMessage+XEP_0085.h"
#import "AppKit/NSStringDrawing.h"

@implementation OSPChatViewController

#pragma mark - Intialization
- (id) initWithRemoteJid:(XMPPJID *)rjid
{
    self = [super initWithNibName:@"chatView" bundle:nil];
    if (self)
    {
        localJid = [[self xmppStream] myJID];
        remoteJid = rjid;
        typing = NO;
        dummycell = [[NSTextFieldCell alloc] init];
        [dummycell setLineBreakMode:NSLineBreakByWordWrapping];
        [dummycell setFont:[NSFont fontWithName:@"LucidaGrande" size:13.0]];
    }

    return self;
}


- (void) loadView
{
    [self myViewWillLoad];
    [super loadView];
    [self myViewDidLoad];
}


- (void) myViewWillLoad
{
}


- (void) myViewDidLoad
{
    [self setArrayControllerFetchPredicate];
    [self setArrayControllerFilterPredicate];

    [inputField bind:@"hidden" toObject:[[NSApp delegate] connectionController] withKeyPath:@"connectionState" options:[NSDictionary dictionaryWithObjectsAndKeys:@"OSPConnectionStateToNotAuthenticatedTransformer",NSValueTransformerNameBindingOption, nil]];
    
    [_scrollView setDelegate:self];
}


- (void) ptrScrollViewDidTriggerRefresh:(id)sender
{
    
    [arrayController fetchMore:self];
}


- (void) setArrayControllerFetchPredicate
{
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(bareJidStr == %@) AND (streamBareJidStr == %@)", remoteJid.bare, [[[[NSApp delegate] xmppStream] myJID] bare]];
    [arrayController setFetchPredicate:fetchPredicate];
}


- (void) setArrayControllerFilterPredicate
{
}


- (void) focusInputField
{
    [inputField becomeFirstResponder];
}

/* 
    A little hack to scroll to the bottom of the chat programatically once the chat becomes active, as somehow the scrollview
    forgets that its scroll position
 */
- (void) scrollToBottom {
    NSInteger numberOfRows = [tableView numberOfRows];
    [tableView scrollRowToVisible:numberOfRows - 1];
}

#pragma mark - Message sending
- (IBAction) send:(id)sender
{
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addActiveChatState];

    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];

    [body setStringValue:[sender stringValue]];
    [message addChild:body];

    [[self xmppStream] sendElement:message];
    [message addAttributeWithName:@"from" stringValue:[localJid full]];

    [sender setStringValue:@""];
}


#pragma mark - Message display
/*!
 * @brief Returns the correct TableCellViews depending on where in a message streak a given row is and wheter it is incomming or outgoing
 */
- (NSView *) tableView:(NSTableView *)aTableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row
{
    // This method isn't a beauty. TODO: Refactor

    OSPMessageTableCellView *view = nil;
    XMPPMessageArchiving_Message_CoreDataObject *item = [[arrayController arrangedObjects] objectAtIndex:row];
    BOOL isLastInStreak = [self isLastInStreak:row tableView:tableView item:item];

    if ([item isOutgoing])
    {
        if ( isLastInStreak && (row != [tableView numberOfRows] - 1) )
        {
            view = [aTableView makeViewWithIdentifier:@"lastOutgoingMessageCellView" owner:self];
        }
        else
        {
            view = [aTableView makeViewWithIdentifier:@"outgoingMessageCellView" owner:self];
        }
    }
    else
    {
        if ( isLastInStreak && (row != [tableView numberOfRows] - 1) )
        {
            view = [aTableView makeViewWithIdentifier:@"lastIncommingMessageCellView" owner:self];
        }
        else
        {
            view = [aTableView makeViewWithIdentifier:@"incommingMessageCellView" owner:self];
        }
    }

    return view;
}


/*!
 * @brief Checks if a row is the last one in a given message streak
 */
- (BOOL) isLastInStreak:(NSInteger)row tableView:(NSTableView *)aTableView item:(XMPPMessageArchiving_Message_CoreDataObject *)item
{
    if (row == [aTableView numberOfRows] - 1)
    {
        return YES;
    }

    XMPPMessageArchiving_Message_CoreDataObject *nextItem = [[arrayController arrangedObjects] objectAtIndex:row + 1];

    BOOL currentRowOutgoing = item.isOutgoing;
    BOOL nextRowOutgoing = nextItem.isOutgoing;

    if ( (currentRowOutgoing && nextRowOutgoing) || (!currentRowOutgoing && !nextRowOutgoing) )
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


/*!
 * @brief Calculates the height of each row depending on how much vertical space the message body requires approximately.
 * The actual NSTextField expands automatically via Cocoa Auto Layout, we just have to give it enough room to expand or it will cut it's excess content.
 */
- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CGFloat width = [messageTableColumn width] - 25 - 25 - 25 - 80;

    NSString *string = [(XMPPMessageArchiving_Message_CoreDataObject *)[[arrayController arrangedObjects] objectAtIndex:row] body];

    CGFloat textwidth = [string sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"LucidaGrande" size:13.00] forKey:@"NSFontAttributeName"]].width;

    float newHeight = MAX(ceil(textwidth / width) * 17 + 18, 35.0);
    return newHeight;


}

- (void) tableViewColumnDidResize:(NSNotification *)aNotification
{
    NSRange visibleRows = [tableView rowsInRect:_scrollView.contentView.bounds];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
    [NSAnimationContext endGrouping];
}

#pragma mark - Typing notifications
/*!
 * @brief Starts a timer for typing notification when the user starts entering text in the input field
 */
- (void) controlTextDidBeginEditing:(NSNotification *)notification
{
    [self sendChatStateComposing];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(userStopedTyping) userInfo:nil repeats:NO];
    typing = YES;
}


/*!
 * @brief Refreshes timer when new text is entered,  resends typing notification ajd refreshes timer when user restarts typing
 */
- (void) controlTextDidChange:(NSNotification *)notification
{
    if (!typing)
    {
        [self sendChatStateComposing];
        typing = YES;
    }

    [inputTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(userStopedTyping) userInfo:nil repeats:NO];
}


/*!
 * @brief Sends active state when timer expires. Sending paused state would make more sense, but most clients support just active and typing states
 */
- (void) userStopedTyping
{
    [self sendChatStateActive];
    typing = NO;
}


- (void) sendChatStateActive
{
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addActiveChatState];
    [[self xmppStream] sendElement:message];
}


- (void) sendChatStateComposing
{
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addComposingChatState];
    [[self xmppStream] sendElement:message];
}


#pragma mark -  Convenience Accessors
- (XMPPStream *) xmppStream
{
    return [[NSApp delegate] xmppStream];
}


- (OSPRosterController *) rosterController
{
    return [[NSApp delegate] rosterController];
}


- (XMPPRoster *) xmppRoster
{
    return [[NSApp delegate] xmppRosterModule];
}


- (OSPRosterStorage *) xmppRosterStorage
{
    return [[NSApp delegate] xmppRosterStorage];
}


- (NSManagedObjectContext *) managedObjectContext
{
    return [[NSApp delegate] managedObjectContext];
}


@end
