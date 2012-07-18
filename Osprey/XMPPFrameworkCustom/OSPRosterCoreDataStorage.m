#import "OSPRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"

@implementation OSPRosterCoreDataStorage 

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream {
    // Overwritten to prevent nuking of roster database on every startup
}

- (void)mergeChangesFromContextDidSaveNotificationOnStorageThread:(NSNotification *)notification {
    dispatch_sync(storageQueue, ^{
        DDLogVerbose(@"Mergin on storage queue");
        NSAssert(dispatch_get_current_queue() == storageQueue, @"Invoked on incorrect queue");
        [[self managedObjectContext] performSelector:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification];    
    });
}

@end
