#import "OSPLastIncommingMessageTableCellView.h"

/*!
 * @class OSPLastIncommingMessageTableCellView.h
 * @brief Handles drawing of the last incomming message in a streak
 *
 * This class handles drawing the last message in an incomming streak (multiple messages from the same sender in a row)
 * To have lines drawn before and after each streak, this class and it's counterpart the OSPLastOutgoingMessageTableCellView have
 * to draw the same lines at their bottom
 */
@implementation OSPLastIncommingMessageTableCellView
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
 * @brief Draws the bottom border of the last message in an incomming streak. Background and text color are handled in superclasses
 */
- (void) drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSColor *topBorderColor = [NSColor colorFromHexRGB:@"e9e9e9"];
    NSBezierPath *topBorder = [[NSBezierPath alloc] init];

    [topBorder moveToPoint:NSMakePoint(0.0, 0.0 + 0.5)];
    [topBorder lineToPoint:NSMakePoint(self.bounds.size.width, 0.0 + 0.5)];
    [topBorderColor set];
    [topBorder stroke];
}


@end
