#import "OSPTableView.h"

@implementation OSPTableView

- (BOOL)acceptsFirstResponder 
{
    return NO;
}

// Disable blue row frame for right clicked rows
- (void)drawContextMenuHighlightForRow:(int)row {

}


@end
