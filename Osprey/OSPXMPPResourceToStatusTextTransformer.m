#import "OSPXMPPResourceToStatusTextTransformer.h"
#import "XMPPResourceCoreDataStorageObject.h"
@implementation OSPXMPPResourceToStatusTextTransformer
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass

{
    return [NSNumber class];
}
- (id)transformedValue:(id)value

{
    if (value == nil || ![[[NSApp delegate] xmppStream] isAuthenticated]) {
        return @"Offline";
    }
    
    switch ([value intValue]) {
        case 3:
            return @"Online";
            break;
        case 2: 
            return @"Away";
        case 0: 
            return @"Do not distrub";
        case 1:
            return @"Extended away";
        case 4:
            return @"Free for chat";
        default:
            return @"Unknown";
    }
    
}

@end
