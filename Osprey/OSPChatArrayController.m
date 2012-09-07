#import "OSPChatArrayController.h"

@implementation OSPChatArrayController
- (void)awakeFromNib

{
    NSLog(@"here");
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [self setSortDescriptors:[NSArray arrayWithObject:sort]];
    [super awakeFromNib];
    
}

@end
