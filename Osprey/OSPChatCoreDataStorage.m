#import "OSPChatCoreDataStorage.h"

@implementation OSPChatCoreDataStorage

- (void)mainThreadManagedObjectContextDidMergeChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"chatStorageMainThreadManagedObjectContextDidMergeChanges" object:nil];
}
@end
