#import "XMPPUserCoreDataStorageObject+NotSubscribed.h"

@implementation XMPPUserCoreDataStorageObject (NotSubscribed)

- (BOOL) isNotSubscribed
{
    NSString *subscription = self.subscription;
    NSString *ask = self.ask;

    if ([subscription isEqualToString:@"none"] || [subscription isEqualToString:@"from"])
    {
        if (![ask isEqualToString:@"subscribe"])
        {
            return YES;
        }
    }

    return NO;
}


@end
