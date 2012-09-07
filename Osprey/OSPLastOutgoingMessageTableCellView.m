//
//  OSPLastOutgoingMessageTableCellView.m
//  Osprey
//
//  Created by Alexander Rust on 07.09.12.
//  Copyright (c) 2012 IBM Deutschland GmbH. All rights reserved.
//

#import "OSPLastOutgoingMessageTableCellView.h"
#import "NSColor+HexAdditions.h"

@implementation OSPLastOutgoingMessageTableCellView
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
    

    NSColor *topBorderColor = [NSColor colorFromHexRGB:@"e9e9e9"];
    NSBezierPath *topBorder = [[NSBezierPath alloc] init];
    
    [topBorder moveToPoint:NSMakePoint(0.0, 0.0+0.5)];
    [topBorder lineToPoint:NSMakePoint(self.bounds.size.width, 0.0+0.5)];
    [topBorderColor set];
    [topBorder stroke];
    
}
@end

