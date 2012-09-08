#import "OSPDateToMessageTimeStringTransformer.h"

@implementation OSPDateToMessageTimeStringTransformer
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
    return [NSString class];
}
- (id)transformedValue:(id)value

{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    return [formatter stringFromDate:(NSDate*)value];
}
@end
