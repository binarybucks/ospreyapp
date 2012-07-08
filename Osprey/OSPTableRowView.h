#import <AppKit/AppKit.h>

@interface OSPTableRowView : NSTableRowView {
    NSColor *gradientTopColor;
    NSColor *gradientBottomColor;
    NSGradient *fillGradient;
    
    NSColor *bottomBorderColor;
    NSColor *topBorderColor;
    
    NSBezierPath* bottomBorder;
    NSBezierPath* topBorder;
    
    
    NSBezierPath* topHighlightBorder;
    NSColor *topHighlightBorderColor;

}

@end
