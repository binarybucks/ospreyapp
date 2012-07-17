#import "OSPRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"

@implementation OSPRosterCoreDataStorage 

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream {
    // Overwritten to prevent nuking of roster database on every startup
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath forUserWithJid:(XMPPJID*)jid onStream:(XMPPStream*)stream {
    
    dispatch_async(storageQueue, ^{
        [[self userForJID:jid xmppStream:stream managedObjectContext:self.managedObjectContext] setValue:value forKeyPath:keyPath];
        NSError *error = nil;
        if (!   [[self managedObjectContext ] save:&error]) {
        DDLogError(@"ManagedObjectContext save failed");
        DDLogError(@"%@",[error description]);
    }

    });
}

@end
