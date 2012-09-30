#import "OSPMessageTableCellView.h"

/*!
 * @class OSPMessageTableCellView.h
 * @brief Generic class that handles drawing of messages
 *
 * This class handles drawing of generic characteristics that are common to all messages no matter if they are incomming or outgoing
 */
@implementation OSPMessageTableCellView

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
 * @brief Sets the text color for incomming and outgoing a messages. Background drawing is handled by subclasses
 */
- (void) drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    NSColor *textColor = [NSColor colorFromHexRGB:@"969696"];
    self.body.textColor = textColor;
    self.timestamp.textColor = textColor;
}


@end
