#import "XMPPPresence+NiceShow.h"

@implementation XMPPPresence (NiceShow)

- (NSString*)niceShow {
        NSString *show = [self show];
        
        if([show isEqualToString:@"dnd"])
            return @"Dnd";
        if([show isEqualToString:@"xa"])
            return @"Extended away";
        if([show isEqualToString:@"away"])
            return @"Away";
        return @"Online";
}

@end
