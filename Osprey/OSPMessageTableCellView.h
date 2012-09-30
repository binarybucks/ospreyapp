#import <Cocoa/Cocoa.h>
#import "NSColor+HexAdditions.h"

@interface OSPMessageTableCellView : NSTableCellView {
}

@property (weak) IBOutlet NSTextField *username;
@property (weak) IBOutlet NSTextField *body;
@property (weak) IBOutlet NSTextField *timestamp;

@end
