#import "OSPRosterCoreDataStorage.h"

@implementation OSPRosterCoreDataStorage

- (void)mainThreadManagedObjectContextDidMergeChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges" object:nil];
}

@end
