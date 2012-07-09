#import "OSPTableRowView.h"
#import "NSColor+HexAdditions.h"
@implementation OSPTableRowView

// allways use the active (blue highlight)
- (BOOL) isEmphasized {
    return YES;
}

- (void)awakeFromNib {
        gradientTopColor = [NSColor colorFromHexRGB:@"78bee5"];
        gradientBottomColor =  [NSColor colorFromHexRGB:@"469bcf"];
        fillGradient = [[NSGradient alloc] initWithStartingColor:gradientBottomColor endingColor:gradientTopColor];
        
        bottomBorderColor = [NSColor colorFromHexRGB:@"1e70a5"];
        topBorderColor = [NSColor colorFromHexRGB:@"3d87b6"];
        topHighlightBorderColor  = [NSColor colorFromHexRGB:@"8bcae9"];

        
        bottomBorder = [[NSBezierPath alloc] init];
        topBorder = [[NSBezierPath alloc] init];
        topHighlightBorder = [[NSBezierPath alloc] init];;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
        // Using dirtyRect to draw causes strange effects when scrolling
        // Better use self.bounds to draw
        
        // Draw gradient 
        [fillGradient drawInRect:self.bounds angle:-90];    
        // Draw bottom-border
        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
        [topBorder moveToPoint:NSMakePoint(0.0, 0.0+0.5)];
        [topBorder lineToPoint:NSMakePoint(self.bounds.size.width, 0.0+0.5)];
        [topBorderColor set];
        [topBorder stroke];
    
    [topHighlightBorder moveToPoint:NSMakePoint(0.0, 1.0+0.5)];
    [topHighlightBorder lineToPoint:NSMakePoint(self.bounds.size.width, 1.0+0.5)];
    [topHighlightBorderColor set];
    [topHighlightBorder stroke];
    
    
        // Draw top-border
        [bottomBorder moveToPoint:NSMakePoint(0.0, self.bounds.size.height-0.5)];
        [bottomBorder lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height-0.5)];
        [bottomBorderColor set];
        [bottomBorder stroke];
    
}



@end
