#import <Foundation/Foundation.h>
#import "XMPPUserCoreDataStorageObject.h"

@interface OSPUserCoreDataStorageObject : XMPPUserCoreDataStorageObject <XMPPUser> {
    
}

@property (nonatomic, retain) NSDate *chatOpened;

@end
