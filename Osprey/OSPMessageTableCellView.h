#import <Cocoa/Cocoa.h>

@interface OSPMessageTableCellView : NSTableCellView {
    
}

@property (weak) IBOutlet NSTextField* username;
@property (weak) IBOutlet NSTextField* body;
@property (weak) IBOutlet NSTextField* timestamp;

@property (assign) BOOL firstInStreak;
@property (assign) BOOL lastInStreak;

@end
