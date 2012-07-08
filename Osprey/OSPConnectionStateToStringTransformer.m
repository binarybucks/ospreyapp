#import "OSPConnectionStateToStringTransformer.h"

@implementation OSPConnectionStateToStringTransformer
+ (Class)transformedValueClass

{
    return [NSString class];
}
- (id)transformedValue:(id)value
{    
    int status = [value intValue];
    NSLog(@"ConnectionState: %d", status);

    if (!status) {
        return @"Disconnected";
    }
    if (status & connecting) {
        return @"Connecting";
    }
    if (status & authenticating) {
        return @"Connecting";
    }
    if (status & authenticated) {
        return @"Authenticated";
    }
    if (status & registering) {
        return @"Registering";
    }
    if (status & registered) {
        return @"Registered";
    }
    return @"Fail";
}

@end
