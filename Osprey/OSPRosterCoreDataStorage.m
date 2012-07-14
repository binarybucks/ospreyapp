#import "OSPRosterCoreDataStorage.h"

@implementation OSPRosterCoreDataStorage 

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream {
    // Overwritten to prevent nuking of roster database on every startup
}


@end
