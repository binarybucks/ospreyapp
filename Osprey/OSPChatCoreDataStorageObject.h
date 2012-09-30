#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface OSPChatCoreDataStorageObject : NSManagedObject {
    NSManagedObjectContext *moc;
    NSEntityDescription *entityDescription;
    NSFetchRequest *request;
    NSPredicate *predicate;
}

@property (nonatomic, retain) NSString *streamBareJidStr;
@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSString *jidStr;
@property (nonatomic, retain) NSNumber *muted;
@property (nonatomic, retain) NSNumber *unreadCount;
@property (nonatomic, retain) NSDecimalNumber *order;
@property (readonly, weak) id userStorageObject;
@property (nonatomic, retain) NSNumber *isTyping;
@property (nonatomic, readonly, retain) NSString *displayName;

- (void) refetchUserStorageObject;

@end
