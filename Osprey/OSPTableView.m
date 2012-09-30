#import "OSPTableView.h"

@implementation OSPTableView

- (BOOL) acceptsFirstResponder
{
    return NO;
}


// Disable blue row frame for right clicked rows
- (void) drawContextMenuHighlightForRow:(int)row
{
}

// Preserves selection on reloadData, as the NSArrayController functionality is quite flaky. This isn't a ideal implementation as it does not consider
// the insetion of new items before the selected row. However, as currently new items are inserted only at the end of the list, this isn't that bad.
// Even though: TODO: make this independent of the position at which items are inserted
- (void) reloadData {
    NSInteger selectedRow = [self selectedRow];
    [super reloadData];
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}

@end
