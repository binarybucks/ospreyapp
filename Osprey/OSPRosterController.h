#import <Foundation/Foundation.h>
#import "OSPRosterTableCellView.h"
#import "Types.h"
#import "XMPPRoster.h"

@interface OSPRosterController : NSViewController <NSTableViewDelegate, XMPPRosterDelegate> {
    IBOutlet NSTableView * rosterTable;
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSScrollView *scrollView;
    
    IBOutlet NSTextField *jidField;
    IBOutlet NSTextField *xofyField;
    IBOutlet NSWindow *requestWindow;
    NSMutableArray *requests;
    int jidIndex;

    BOOL initialAwakeFromNibCallFinished;
}
@property(nonatomic, retain) IBOutlet NSSearchField *searchField;

- (IBAction)filterRoster:(id)sender;
- (IBAction)acceptRequest:(id)sender;
- (IBAction)rejectRequest:(id)sender;

@end
