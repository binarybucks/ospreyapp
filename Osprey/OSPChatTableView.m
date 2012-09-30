#import "OSPChatTableView.h"

@implementation OSPChatTableView

- (void) awakeFromNib
{
    [self setIntercellSpacing:NSMakeSize(0.0, 0.0)];
}


- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
    }

    return self;
}


- (void) reloadData
{
    [super reloadData];
    NSInteger numberOfRows = [self numberOfRows];
    NSRange rowsInRect = [self rowsInRect:self.superview.bounds];
    NSInteger lastVisibleRow = rowsInRect.location + rowsInRect.length;

    if (lastVisibleRow == numberOfRows - 1)
    {
        [self scrollRowToVisible:numberOfRows - 1];
    }
}


@end
