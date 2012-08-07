#import "OSPChatCoreDataStorageObject.h"


@implementation OSPChatCoreDataStorageObject

@dynamic streamBareJidStr;
@dynamic type;
@dynamic jidStr;
@dynamic muted;
@dynamic order;
@dynamic userStorageObjects;


- (id) userStorageObject {
    LOGFUNCTIONCALL
    
    NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                         inManagedObjectContext:moc];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(jidStr == %@) AND (streamBareJidStr == %@)", self.jidStr, self.streamBareJidStr];
    [request setPredicate:predicate];
    NSArray *array = [moc executeFetchRequest:request error:nil];
    DDLogVerbose(@"Chat user jid : %@", self.jidStr);
    DDLogVerbose(@"Chat stream jid : %@", self.streamBareJidStr);
    DDLogVerbose(@"Associated user object jid : %@", ((OSPUserStorageObject*)array.lastObject).jid);
    return array.lastObject;
}

@end
