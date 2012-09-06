//
//  OSPChatTableView.m
//  Osprey
//
//  Created by Alexander Rust on 05.09.12.
//  Copyright (c) 2012 IBM Deutschland GmbH. All rights reserved.
//

#import "OSPChatTableView.h"

@implementation OSPChatTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void) reloadData {
    [super reloadData];
    NSInteger numberOfRows = [self numberOfRows];
    NSRange rowsInRect = [self rowsInRect:self.superview.bounds];
    NSInteger lastVisibleRow = rowsInRect.location + rowsInRect.length;
    
    if (lastVisibleRow == numberOfRows-1) {
        [self scrollRowToVisible:numberOfRows - 1];
    }
}


@end
