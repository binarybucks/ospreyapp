#import "OSPOutgoingMessageTableCellView.h"
#import "NSColor+HexAdditions.h"

@implementation OSPOutgoingMessageTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor colorFromHexRGB:@"f5f5f5"] set];
    NSRectFill(dirtyRect);

    [super drawRect:dirtyRect];
}



@end
