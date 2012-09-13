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
        dummycell = [[NSTextFieldCell alloc] init];
        [dummycell setLineBreakMode:NSLineBreakByWordWrapping];
        [dummycell setFont:[NSFont fontWithName:@"System" size:13.0]];
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:scrollView.contentView];

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
- (NSView *)tableView:(NSTableView *)aTableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    // This method isn't a beauty. TODO: Refactor
    
    OSPMessageTableCellView *view = nil;
    XMPPMessageArchiving_Message_CoreDataObject *item = [[arrayController arrangedObjects] objectAtIndex:row];
    BOOL isLastInStreak = [self isLastInStreak:row tableView:tableView item:item];

    if ([item isOutgoing]) {
        if (isLastInStreak && (row != [tableView numberOfRows]-1)) {
            view = [aTableView makeViewWithIdentifier:@"lastOutgoingMessageCellView" owner:self];
        } else {
            view = [aTableView makeViewWithIdentifier:@"outgoingMessageCellView" owner:self];
        }
    } else {
        if (isLastInStreak  && (row != [tableView numberOfRows]-1)) {
            view = [aTableView makeViewWithIdentifier:@"lastIncommingMessageCellView" owner:self];
        } else {
            view = [aTableView makeViewWithIdentifier:@"incommingMessageCellView" owner:self];
        }
    }
    return view;
}

/*!
 * @brief Checks if a row is the last one in a given message streak
 */
- (BOOL)isLastInStreak:(NSInteger)row tableView:(NSTableView*)aTableView item:(XMPPMessageArchiving_Message_CoreDataObject *)item{
    if (row == [aTableView numberOfRows]-1) {
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

/*!
 * @brief Calculates the height of each row depending on how much vertical space the message body requires approximately. 
 * The actual NSTextField expands automatically via Cocoa Auto Layout, we just have to give it enough room to expand or it will cut it's excess content. 
 */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{

    
    CGFloat width = [messageTableColumn width]-25-25-25-80;
    
    NSString *string =  [(XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row] body];
    
    CGFloat textwidth = [string sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"LucidaGrande" size:13.00] forKey:@"NSFontAttributeName"]].width;
    
    float newHeight = MAX(ceil(textwidth/width)*17+18, 35.0);
    return newHeight;
    
// KIND OF WORKING
//    CGFloat heightOfRow;
//    NSString *string =  [(XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row] body];
//    
//    if (!string) {
//        string = @"NIL";
//    }
//    if (messageTableColumn)
//    {
//        [dummycell setStringValue:string];
//        NSRect myRect = NSMakeRect(0, 0, [messageTableColumn width]-25-25-25-86, CGFLOAT_MAX);
//        heightOfRow =  ([dummycell cellSizeForBounds:myRect].height+18.0+6);
//        NSLog(@"string %@", string);
//        NSLog(@"width: %f", [messageTableColumn width]-25-25-25-80);
//        NSLog(@"proposed height: %f", heightOfRow);
//    }
//    
//    return MAX(heightOfRow,35.0);

    
    
    
    
    
    
    
    
    
    
    
    /// MEH CODE
    //    NSString *message = [(XMPPMessageArchiving_Message_CoreDataObject*)[[arrayController arrangedObjects] objectAtIndex:row] body];
//
//    NSTextFieldCell *cell = [[NSTextFieldCell alloc] init];
//    [cell setLineBreakMode:NSLineBreakByWordWrapping];
//    [cell setStringValue:message];
//    
//    NSSize size = [cell cellSizeForBounds:NSMakeRect(0.0, 0.0, [messageTableColumn width]-25-25-25-80, 1000.0)];
//    
//    return size.height+18;
    
//    NSSize stringSize = [message sizeWithAttributes:[[NSDictionary alloc] init]];
//    
//    CGFloat effectiveWitdthAvailableForMessageBody = [messageTableColumn width]-25-25-25-80;
//    CGFloat stringWitdh = stringSize.width;
//    if (stringSize.width > effectiveWitdthAvailableForMessageBody) {
//        NSLog(@"string witdh: %f", stringSize.width);
//        NSLog(@"effectiveWitdthAvailableForMessageBody : %f", effectiveWitdthAvailableForMessageBody);
//
//        NSLog(@"requiring rows: %f", ceil(stringWitdh / effectiveWitdthAvailableForMessageBody));
//        // ceil(stringWitdh / effectiveWitdthAvailableForMessageBody) gives number of required rows
//        // 17.0 is actual row height, while 9.0 are padding at top and bottom
//        CGFloat space = (ceil(stringWitdh / effectiveWitdthAvailableForMessageBody) * 17.0) + 9.0 + 9.0;
//        NSLog(@"height: %f", space);
//        return (ceil(stringWitdh / effectiveWitdthAvailableForMessageBody) * 17.0) + 9.0 + 9.0;
//    } else {
//        return 35.0;
//    }
//    NSTextStorage * storage = [[NSTextStorage alloc] initWithString:message];
//    
//    NSTextContainer * container = [[NSTextContainer alloc] initWithContainerSize: NSMakeSize([messageTableColumn width]-25-25-25-80, 500.0)];
//    NSLayoutManager * manager = [[NSLayoutManager alloc] init];
//    
//    [manager addTextContainer: container];
//    [storage addLayoutManager: manager];
//    
//    [manager glyphRangeForTextContainer: container];
//    
//    NSRect idealRect = [manager usedRectForTextContainer: container];
//    
//    
//    // Include a fudge factor.
//    return idealRect.size.height + 35;

}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    NSRange visibleRows = [tableView rowsInRect:scrollView.contentView.bounds];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
    [NSAnimationContext endGrouping];
}


//// Triggers recalculating of row heights when window size changes
//- (void)scrollViewContentBoundsDidChange:(NSNotification*)notification
//{
//    NSRange visibleRows = [tableView rowsInRect:scrollView.contentView.bounds];
//    [NSAnimationContext beginGrouping];
//    [[NSAnimationContext currentContext] setDuration:0];
//    [tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
//    [NSAnimationContext endGrouping];
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
