#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OSPChatCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString * streamBareJidStr;
@property (nonatomic, retain) NSDecimalNumber * type;
@property (nonatomic, retain) NSString *jidStr;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSDecimalNumber * order;
@property (nonatomic, retain) NSArray *userStorageObjects;
@property (readonly, retain) id userStorageObject;
@end
