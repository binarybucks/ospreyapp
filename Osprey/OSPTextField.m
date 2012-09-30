#import "OSPTextField.h"

@implementation OSPTextField

- (BOOL) acceptsFirstResponder
{
    return YES;
}


- (id) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setDrawsBackground:NO];

        if ([[self cell] controlSize] == NSMiniControlSize)             // doesn't work well for mini size - text needs to be adjusted up
        {
            [self setFont:[NSFont systemFontOfSize:8.0]];
        }
        else if ([[self cell] controlSize] == NSSmallControlSize)
        {
            [self setFont:[NSFont systemFontOfSize:9.4]];
        }
        else
        {
            [self setFont:[NSFont systemFontOfSize:11.88]];
        }
    }

    return self;
}


- (void) drawRect:(NSRect)dirtyRect
{
    // bottom white highlight
    NSRect hightlightFrame = NSMakeRect(0.0, 10.0, [self bounds].size.width, [self bounds].size.height - 10.0);
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.394] set];
    [[NSBezierPath bezierPathWithRoundedRect:hightlightFrame xRadius:3.6 yRadius:3.6] fill];

    // black outline
    NSRect blackOutlineFrame = NSMakeRect(0.0, 0.0, [self bounds].size.width, [self bounds].size.height - 1.0);
    NSGradient *gradient = nil;
    if ([NSApp isActive] && [self isEnabled])
    {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.24 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.374 alpha:1.0]];
    }
    else
    {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]];
    }

    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:3.6 yRadius:3.6] angle:90];

    // top inner shadow
    NSRect shadowFrame = NSMakeRect(1, 1, [self bounds].size.width - 2.0, 10.0);
    [[NSColor colorWithCalibratedWhite:0.88 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:2.9 yRadius:2.9] fill];

    // main white area
    NSRect whiteFrame = NSMakeRect(1, 2, [self bounds].size.width - 2.0, [self bounds].size.height - 4.0);
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithRoundedRect:whiteFrame xRadius:2.6 yRadius:2.6] fill];

    // draw the keyboard focus ring if we're the first responder and the application is active
    if ( ([[self window] firstResponder] == [self currentEditor]) && [NSApp isActive] )
    {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:3.6 yRadius:3.6] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
    else
    {
        // I don't like that the point to draw at is hard-coded, but it works for now
        [[self attributedStringValue] drawInRect:NSMakeRect(4.0, 3.0, [self bounds].size.width - 8.0, [self bounds].size.width - 6.0)];
    }
}


@end
