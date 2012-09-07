#import "OSPMessageTableCellView.h"
#import "NSColor+HexAdditions.h"
@implementation OSPMessageTableCellView

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
    NSColor *textColor = [NSColor colorFromHexRGB:@"969696"];
    self.body.textColor = textColor;
    self.timestamp.textColor = textColor;
}

@end
