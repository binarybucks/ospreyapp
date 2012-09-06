#import "OSPChatArrayController.h"

@implementation OSPChatArrayController
- (void)awakeFromNib

{
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [self setSortDescriptors:[NSArray arrayWithObject:sort]];
    [super awakeFromNib];
    
}

@end
