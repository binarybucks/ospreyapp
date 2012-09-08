#import "OSPChatViewController.h"
#import "OSPMessageTableCellView.h"
#import "Types.h"
#import "NSColor+HexAdditions.h"
#import "XMPPMessage+XEP_0224.h"
#import "XMPPMessage+XEP_0085.h"
#import "AppKit/NSStringDrawing.h"

@implementation OSPChatViewController

#pragma mark - Intialization
- (id)initWithRemoteJid:(XMPPJID*)rjid
{
    self = [super initWithNibName:@"chatView" bundle:nil];
    if (self) {
        localJid = [[self xmppStream] myJID];
        remoteJid = rjid;
        typing = NO;
    }
    return self;
    
}

- (void)loadView {
    [self myViewWillLoad];
    [super loadView];
    [self myViewDidLoad];
}

- (void)myViewWillLoad {
}

- (void)myViewDidLoad {
    [self setArrayControllerFetchPredicate];
    [self setArrayControllerFilterPredicate];
    
    [inputField bind:@"hidden" toObject:[[NSApp delegate] connectionController] withKeyPath:@"connectionState" options:[NSDictionary dictionaryWithObjectsAndKeys:@"OSPConnectionStateToNotAuthenticatedTransformer",NSValueTransformerNameBindingOption, nil]];
}

- (void) setArrayControllerFetchPredicate {
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(bareJidStr == %@) AND (streamBareJidStr == %@)", remoteJid.bare, [[[[NSApp delegate] xmppStream] myJID] bare]];
    [arrayController setFetchPredicate:fetchPredicate];
}

- (void) setArrayControllerFilterPredicate {
    
}


- (void) focusInputField {
    [inputField becomeFirstResponder];
}

# pragma mark - Message sending 
- (IBAction) send:(id)sender {
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    [message addActiveChatState];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];

    [body setStringValue:[sender stringValue]];
    [message addChild:body];
    
    [[self xmppStream] sendElement:message];
    [message addAttributeWithName:@"from" stringValue:[localJid full]];
        
    [sender setStringValue:@""];
}

# pragma mark - Message display
/*!
 * @brief Returns the correct TableCellViews depending on where in a message streak a given row is and wheter it is incomming or outgoing
 */
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    // This method isn't a beauty. TODO: Refactor
    
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

/*!
 * @brief Checks if a row is the last one in a given message streak
 */
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

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    // filteredMessageCache is an NSArray of the log entries currently displayed
//    LogEntry* logEntry = [filteredMessageCache objectAtIndex:row];
    
    // messageColumn is the NSTableColumn displaying the long strings to be wrapped
    
    // rowview should just have one subview, giving us the TableCelLView with all the content

    NSString *message = [(XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row] body];
    NSSize stringSize = [message sizeWithAttributes:[[NSDictionary alloc] init]];
    NSInteger effectiveWitdthAvailableForMessageBody = [messageTableColumn width]-25-25-25-80;
    NSInteger stringWitdh = stringSize.width;
    if (stringSize.width > effectiveWitdthAvailableForMessageBody) {
        
        // approximateNumberOfLines * lineHeight + paddingTopAndBottom
        return (stringWitdh / effectiveWitdthAvailableForMessageBody) * 17 + 9 + 9;
//        return 60.0;
    } else {
        return 35.0;
    }
    
    
    //    OSPMessageTableCellView *cellView = [[[tableView rowViewAtRow:row makeIfNecessary:NO] subviews] objectAtIndex:0];

    //    NSTextField *messageBody = [cellView body];

    
//    //Calculate the expected size based on the font and linebreak mode of the label
//    CGFloat maxWidth = cellView.bounds.size.width - 100;
//    CGFloat maxHeight = 9999;
//    CGSize maximumLabelSize = CGSizeMake(maxWidth,maxHeight);
    
//
//    NSSize bounds = [[messageBody cell] cellSizeForBounds:cellView.bounds];
//
//    NSRect frame = [messageBody frame] ;
//    frame.size.width = bounds.width ;
//    frame.size.height = bounds.height ;
//    [messageBody setFrame:frame] ;
//    [messageBody setNeedsDisplay:YES];
//
//    //    CGSize expectedLabelSize = [self sizeWithFont:[NSFont systemFontOfSize:size] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
//    
//    return bounds.height;
}
//boundingRectWithSize:size options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:attributes
    //    NSSize *messageBodySize = [[messageBody stringValue] sizeWithWidth:200.0 andFont:[messageBody font]];
//
//    CGFloat columnWidth = [messageTableColumn width];
//    
//    // My LogEntry class has a messageSize NSSize ivar. It would be prettier if it was not directly in the model class...
//    NSSize stringSize = messageBody.stringValue;
//    
//    if (stringSize.width < 0.0)
//    {
//        // messageCell is the NSTextFieldCell messageColumn's dataCell
//        [messageCell setStringValue:logEntry.message];
//        stringSize = [messageCell cellSizeForBounds:NSMakeRect(0.0, 0.0, FLT_MAX, FLT_MAX)];
//        logEntry.messageSize = stringSize;
//    }
//    
//    CGFloat rowHeight = ceilf(stringSize.width / columnWidth) * [tableView rowHeight];
//    
//    return MAX(rowHeight, stringSize.height);

//
//- (void)tableViewColumnDidResize:(NSNotification *)notification
//{
//    NSSize invalidSize = NSMakeSize(-1.0, -1.0);
//    
//    // reset the size of all messages. Again, it would be prettier if it was not directly in the model class...
//    for (LogEntry* logEntry in messageCache)
//    {
//        logEntry.messageSize = invalidSize;
//    }
//    
//    NSRange allIndexes = NSMakeRange(0, [filteredMessageCache count]);
//    [logTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:allIndexes]];
//}




# pragma mark - Typing notifications
/*!
 * @brief Starts a timer for typing notification when the user starts entering text in the input field
 */
- (void)controlTextDidBeginEditing:(NSNotification *)notification{
    [self sendChatStateComposing];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(userStopedTyping) userInfo:nil repeats:NO];
    typing = YES;
}

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

#pragma mark -  Convenience Accessors
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

@end
