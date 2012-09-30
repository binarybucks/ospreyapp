#import <Cocoa/Cocoa.h>

@interface OSPChatArrayController : NSArrayController {
    int _fetchCount;
}
- (IBAction) fetchMore:(id)sender;

@end
