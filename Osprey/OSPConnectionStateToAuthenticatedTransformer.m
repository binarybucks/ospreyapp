#import "OSPConnectionStateToAuthenticatedTransformer.h"

@implementation OSPConnectionStateToAuthenticatedTransformer
+ (Class)transformedValueClass

{
    return [NSNumber class];
}
- (id)transformedValue:(id)value
{    
    int status = [value intValue];
    
    if (status & authenticated) {
        return [NSNumber numberWithBool:YES];
    }
    return [NSNumber numberWithBool:NO];
}
@end