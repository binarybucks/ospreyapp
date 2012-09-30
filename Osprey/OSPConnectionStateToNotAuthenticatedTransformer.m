#import "OSPConnectionStateToNotAuthenticatedTransformer.h"

@implementation OSPConnectionStateToNotAuthenticatedTransformer
+ (Class) transformedValueClass
{
    return [NSNumber class];
}


- (id) transformedValue:(id)value
{
    int status = [value intValue];

    if (status & authenticated)
    {
        return [NSNumber numberWithBool:NO];
    }

    return [NSNumber numberWithBool:YES];
}


@end
