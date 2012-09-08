#import "OSPChatArrayController.h"

@implementation OSPChatArrayController
- (void)awakeFromNib

{
    NSLog(@"here");
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [self setSortDescriptors:[NSArray arrayWithObject:sort]];
    [super awakeFromNib];
    
}
//- (BOOL) fetchWithRequest:(NSFetchRequest *)fetchRequest
//                    merge:(BOOL)merge
//                    error:(NSError **)error
//{
//    LOGFUNCTIONCALL
//    if(fetchRequest)
//        [fetchRequest setFetchLimit:10];
//    
//    NSLog(@"fetchWithRequest: %@", fetchRequest);
//    return [super fetchWithRequest:fetchRequest merge:NO error:error];
//}

@end
