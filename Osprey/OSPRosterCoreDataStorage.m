#import "OSPRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
@implementation OSPRosterCoreDataStorage


// called when changes are propagated to the main thread
- (void)mainThreadManagedObjectContextDidMergeChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges" object:nil];
}

- (NSString*)managedObjectModelName {
    return @"XMPPRoster";
}

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream {
    DDLogVerbose(@"Preventing nuking of roster");
}


@end
