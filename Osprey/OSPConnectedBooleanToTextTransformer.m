#import "OSPConnectedBooleanToTextTransformer.h"

@implementation OSPConnectedBooleanToTextTransformer

+ (Class) transformedValueClass
{
    return [NSString class];
}


- (id) transformedValue:(id)value
{
    if ([(NSNumber *) value isEqualTo:[NSNumber numberWithInt:1]])
    {
        return @"Connected";
    }
    else if ([(NSNumber *) value isEqualTo:[NSNumber numberWithInt:0]])
    {
        return @"Disconnected";
    }

    return @"";
}


@end
