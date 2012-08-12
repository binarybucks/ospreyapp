#import "OSPRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
@implementation OSPRosterCoreDataStorage


// called when changes are propagated to the main thread
- (void)mainThreadManagedObjectContextDidMergeChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges" object:nil];
}


// Locking and unlocking the mainThreadManagedObjectContext prevents "could not fulfill fault" exceptions when connecting and disconnecting rapidly
- (void)willSaveManagedObjectContext
{
    dispatch_sync(dispatch_get_main_queue(), ^{         
        [[self mainThreadManagedObjectContext] lock];
    });
}

- (void)didSaveManagedObjectContext
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[self mainThreadManagedObjectContext] unlock];
    });
}



- (NSString*)managedObjectModelName {
    return @"XMPPRoster";
}

//- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream {
//    DDLogVerbose(@"Preventing nuking of roster");
//}


@end
