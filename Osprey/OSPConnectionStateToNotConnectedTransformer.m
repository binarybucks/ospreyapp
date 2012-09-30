#import "OSPConnectionStateToNotConnectedTransformer.h"

@implementation OSPConnectionStateToNotConnectedTransformer
+ (Class) transformedValueClass
{
    return [NSNumber class];
}


- (id) transformedValue:(id)value
{
    int status = [value intValue];

    if (status == disconnected)
    {
        return [NSNumber numberWithBool:YES];
    }

    return [NSNumber numberWithBool:NO];
}


@end
