#import "OSPCoreDataToNSImageTransformer.h"

@implementation OSPCoreDataToNSImageTransformer

+ (BOOL)allowsReverseTransformation

{
    
    return NO;
    
}

+ (Class)transformedValueClass

{
    
    return [NSImage class];
    
}

- (id)transformedValue:(OSPUserStorageObject*)value

{
    
    if (value.photo != nil)
	{
		return value.photo;
	} 
	else
	{
		NSData *photoData = [[[NSApp delegate] xmppvCardAvatarModule] photoDataForJID:value.jid];
        
		if (photoData != nil)
			return [[NSImage alloc] initWithData:photoData];
		else
            return [NSImage imageNamed:@"Account"];
	}

//    
//    
//    NSData *photoData = [[[NSApp delegate] xmppvCardAvatarModule] photoDataForJID:((OSPUserStorageObject*)value).jid];
//    NSImage *avatar;
//    if (photoData != nil) {
//        avatar = [[NSImage alloc] initWithData:photoData];
//    } else {
//        avatar = [NSImage imageNamed:@"Account"];
//    }
//    
//    return avatar;
    
}

@end
