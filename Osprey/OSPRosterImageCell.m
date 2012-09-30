//
//  OSPRosterImageView.m
//  OSP
//
//  Created by Alexander Rust on 17.06.12.
//  Copyright (c) 2012 IBM Deutschland GmbH. All rights reserved.
//

#import "OSPRosterImageCell.h"
#import "NSColor+HexAdditions.h"
@implementation OSPRosterImageCell

- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSRect imageFrame = frame;
    NSImage *image = [self image];

    [NSGraphicsContext saveGraphicsState];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:imageFrame
                                                         xRadius:3
                                                         yRadius:3];
    [path addClip];

    [image drawInRect:imageFrame
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];
    NSColor *strokeColor = [NSColor colorFromHexRGB:@"000000"];
    [strokeColor set];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceOver];

    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSBezierPath bezierPathWithRoundedRect:frame xRadius:3 yRadius:3] stroke];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:6.0];
    [shadow setShadowOffset:NSMakeSize(0, 3)];
    [shadow set];

    [NSGraphicsContext restoreGraphicsState];
}


//- (void)drawRect:(NSRect)dirtyRect
//{
//    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(dirtyRect, 2, 2) xRadius:5 yRadius:5];
//
//    [path setLineWidth:4.0];
//    [path addClip];
//
//    [self.image drawAtPoint: NSZeroPoint
//                   fromRect:dirtyRect
//                  operation:NSCompositeSourceOver
//                   fraction: 1.0];
//
//    [super drawRect:dirtyRect];
//
//    NSColor *strokeColor;
////    if(self.isSelected)
////    {
////        strokeColor = [NSColor colorFromHexRGB:@"f9eca2"];
////    }
////    else
//        strokeColor = [NSColor colorFromHexRGB:@"000000"];
//
//    [strokeColor set];
//    [NSBezierPath setDefaultLineWidth:4.0];
//    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(dirtyRect, 2, 2) xRadius:5 yRadius:5] stroke];
//}

//- (void)awakeFromNib {
//}
//
//- (void)drawRect:(NSRect)dirtyRect
//{
//    [super drawRect:dirtyRect];
//
//    NSColor *strokeColor;
//    // if(self.isSelected)
//        strokeColor = [NSColor colorFromHexRGB:@"f9eca2"];
//    // else
//    //     strokeColor = [NSColor colorFromHexRGB:@"000000"];
//
//    [strokeColor set];
//    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 1) xRadius:5 yRadius:5] stroke];
//
//
//
//}

@end
