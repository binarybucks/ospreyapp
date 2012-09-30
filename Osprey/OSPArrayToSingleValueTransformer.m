#import "OSPArrayToSingleValueTransformer.h"

@implementation OSPArrayToSingleValueTransformer
+ (Class) transformedValueClass
{
    return [NSArray class];
}


- (id) transformedValue:(NSArray *)value
{
    return [value lastObject];
}


@end
