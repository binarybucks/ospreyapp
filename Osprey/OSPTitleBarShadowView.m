#import "OSPTitleBarShadowView.h"
#import "NSColor+HexAdditions.h"
@implementation OSPTitleBarShadowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        gradientTopColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.2];
        gradientBottomColor =  [NSColor colorWithCalibratedWhite:0.0 alpha:0.01];
        fillGradient = [[NSGradient alloc] initWithStartingColor:gradientBottomColor endingColor:gradientTopColor];

    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [fillGradient drawInRect:dirtyRect angle:90];    
}

@end
