#import <Foundation/Foundation.h>
#import "OSPRosterTableCellView.h"
#import "Types.h"
@interface OSPRosterController : NSViewController <NSTableViewDelegate> {
    IBOutlet NSTableView * rosterTable;
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSScrollView *scrollView;
    BOOL initialAwakeFromNibCallFinished;
}
@property(nonatomic, retain) IBOutlet NSSearchField *searchField;

- (IBAction)filterRoster:(id)sender;
@end
