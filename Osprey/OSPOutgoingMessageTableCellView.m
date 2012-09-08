#import "OSPOutgoingMessageTableCellView.h"

/*!
 * @class OSPOutgoingMessageTableCellView
 * @brief Handles drawing of outgoing messages
 *
 * This class handles drawing of outgoing messages. The text color is currently the same for incomming and outgoing messages, thus this is 
 * handled in [super drawRect:dirtyRect]. Streak lines are drawn by the OSPLastOutgoingMessageTableCellView subclass 
 */
@implementation OSPOutgoingMessageTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/*!
 * @brief Sets the background color of outgoing messages. Text color is handled in superclass
 */
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor colorFromHexRGB:@"f5f5f5"] set];
    NSRectFill(dirtyRect);
}



@end
