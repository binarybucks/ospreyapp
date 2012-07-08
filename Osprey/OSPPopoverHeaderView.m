#import "OSPPopoverHeaderView.h"

@implementation OSPPopoverHeaderView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        gradientTopColor = [NSColor colorWithCalibratedRed:(255.0/255) green:(255.0/255) blue:(255.0/255) alpha:1.0];
        gradientBottomColor = [NSColor colorWithCalibratedRed:(200.0/255) green:(200.0/255) blue:(200.0/255) alpha:1.0];
        fillGradient = [[NSGradient alloc] initWithStartingColor:gradientBottomColor endingColor:gradientTopColor];
        
        bottomOuterBorderColor = [NSColor colorWithCalibratedRed:(133.0/255) green:(133.0/255) blue:(133.0/255) alpha:1.0];
        
        outerBorder = [[NSBezierPath alloc] init];
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw gradient
    [fillGradient drawInRect:dirtyRect angle:90];    
    
    // Draw bottom-border
    [outerBorder moveToPoint:NSMakePoint(0.0, 0.0)];
    [outerBorder lineToPoint:NSMakePoint(dirtyRect.size.width, 0.0)];
    [bottomOuterBorderColor set];
    [outerBorder stroke];
}

@end
