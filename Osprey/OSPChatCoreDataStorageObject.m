#import "OSPChatCoreDataStorageObject.h"

@implementation OSPChatCoreDataStorageObject

@dynamic streamBareJidStr;
@dynamic type;
@dynamic jidStr;
@dynamic muted;
@dynamic order;
@dynamic unreadCount;
@dynamic isTyping;

@synthesize userStorageObject;

- (NSString *) displayName
{
    if (userStorageObject != nil)
    {
        return [self.userStorageObject valueForKey:@"displayName"];
    }
    else
    {
        return [self valueForKey:@"jidStr"];
    }
}


/*!
 * @brief Fetches UserStorageObject associated with that ChatStorageObject from the corresponding store
 * UserStorageObjects reside in a completely different store. Thus, to circumvent subclassing stores set up by
 * the XMPPFramework, we manually controll a cross-store relation by manually fetching the UserStorageObject
 * for this ChatStorageObject. We use the jidStr and streamBareJidStr as foreign keys to a UserStorageObject
 * in the Roster storage.
 * However, we manually have to refetch this object, once it changes in it's store. Therefore the ChatController
 * listens to the rosterStorageMainThreadManagedObjectContextDidMergeChanges, that notifies it when changes to
 * UserStorageObjects were propagated to the MainThread's moc. The ChatController than calls refetchUserStorageObject
 * for all ChatStorageObjects that are currently fetched.
 * To prevent ChatStorageObjects without UserStorageObjects from appearing in the GUI, this method has to be called
 * after a ChatStorageObject has been saved to the moc (it will then be added to the ArrayController and displayed
 * in the GUI) and when it gets fetched (this is mostly when the app is started and ChatStorageObjects are loaded
 * from the store to be displayed in the GUI afterwards)
 */
- (void) refetchUserStorageObject
{
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (error == nil)
    {
        [self willChangeValueForKey:@"userStorageObject"];
        userStorageObject = array.lastObject;
        [self didChangeValueForKey:@"userStorageObject"];
    }
    else
    {
        DDLogError(@"Error: %@", [error description]);
    }

    NSLog(@"jid %@, intShw %d", self.jidStr, ( (XMPPUserCoreDataStorageObject *)self.userStorageObject ).primaryResource.intShow);
}


/*!
 * @brief Prepares fetch request of UserStorageObject. Prevents creation of same requests and predicates of and over again
 */
- (void) prepareUserStorageObjectFetchRequest
{
    moc = [[NSApp delegate] managedObjectContext];
    entityDescription = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:moc];
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    predicate = [NSPredicate predicateWithFormat:@"(jidStr == %@) AND (streamBareJidStr == %@)", self.jidStr, self.streamBareJidStr];
    [request setPredicate:predicate];
}


/*!
 * @brief Prepares and triggers fetch of UserStorageObject after object has been saved to moc
 * When a new object of this class is created and saved, it will be displayed in the GUI shortly after.
 * Thus, as no UserStorageObject has been fetched at that time, we prepare the fetch request with attributes
 * that were set before the save (jidStr, streamBareJidStr) and execute it aferwards.
 * Subsequent calls of refetchUserStorageObject will be triggered by the ChatController's
 * rosterStorageMainThreadManagedObjectContextDidMergeChanges method, when changes to UserStorageObjects in the
 * RosterStorage moc propagate to the MainThread's moc
 */
- (void) didSave
{
    [self prepareUserStorageObjectFetchRequest];
    [self refetchUserStorageObject];
}


/*!
 * @brief Prepares and triggers fetch of UserStorageObject after object has been fetched from moc
 * See didSave for further explanation
 */
- (void) awakeFromFetch
{
    [self prepareUserStorageObjectFetchRequest];
    [self refetchUserStorageObject];
}


- (BOOL) isEqualTo:(OSPChatCoreDataStorageObject *)object
{
    return self.streamBareJidStr == object.streamBareJidStr && self.jidStr == object.jidStr;
}


@end
