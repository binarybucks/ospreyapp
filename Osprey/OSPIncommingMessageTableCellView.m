#import "OSPIncommingMessageTableCellView.h"

/*!
 * @class OSPOutgoingMessageTableCellView
 * @brief Handles drawing of incomming messages
 *
 * This class handles drawing of incomming messages. The text color is currently the same for incomming and outgoing messages, thus this is
 * handled in [super drawRect:dirtyRect]. Streak lines are drawn by the OSPLastOutgoingMessageTableCellView subclass
 */
@implementation OSPIncommingMessageTableCellView

- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
    }

    return self;
}


/*!
 * @brief Sets the background color of incomming messages. Text color is handled in superclass
 */
- (void) drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor colorFromHexRGB:@"ffffff"] set];
    NSRectFill(dirtyRect);
}


@end
