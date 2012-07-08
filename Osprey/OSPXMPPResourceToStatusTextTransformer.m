#import "OSPXMPPResourceToStatusTextTransformer.h"

@implementation OSPXMPPResourceToStatusTextTransformer
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
+ (Class)transformedValueClass

{
    return [NSNumber class];
}
- (id)transformedValue:(id)value

{
    if (value == nil) {
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
