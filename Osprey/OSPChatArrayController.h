#import <Cocoa/Cocoa.h>

@interface OSPChatArrayController : NSArrayController {
    int fetchCount;
}
- (IBAction)fetchMore:(id)sender;

@end
