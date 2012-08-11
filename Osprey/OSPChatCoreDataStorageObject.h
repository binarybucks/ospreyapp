#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OSPChatCoreDataStorageObject : NSManagedObject {
    NSManagedObjectContext *moc;
    NSEntityDescription *entityDescription;
    NSFetchRequest *request;    
    NSPredicate *predicate;

}

@property (nonatomic, retain) NSString * streamBareJidStr;
@property (nonatomic, retain) NSDecimalNumber * type;
@property (nonatomic, retain) NSString *jidStr;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSDecimalNumber * order;
@property (readonly, weak) id userStorageObject;

- (void)refetchUserStorageObject;

@end

