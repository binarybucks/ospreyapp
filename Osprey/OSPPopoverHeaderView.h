#import <Cocoa/Cocoa.h>

@interface OSPPopoverHeaderView : NSView {
    NSColor *gradientTopColor;
    NSColor *gradientBottomColor;
    NSGradient *fillGradient;
    
    NSColor *bottomInnerBorderColor;
    NSColor *bottomOuterBorderColor;
    
    NSBezierPath* innerBorder;
    NSBezierPath* outerBorder;
}

@end
