#import <Cocoa/Cocoa.h>
#import "INAppStoreWindow.h"

@interface OSPConnectionController : NSObject {
    IBOutlet NSMenuItem *offlineMenuItem;
    IBOutlet NSMenuItem *onlineMenuItem;

    IBOutlet NSMenuItem *connectionStateIndicator;
    IBOutlet NSMenuItem *setsOnline;
    IBOutlet NSMenuItem *setsAway;
    IBOutlet NSMenu *statusMenu;

    EConnectionState connectionState;
    EErrorState errorState;
    NSString *errorDescription;
}

@property (assign) BOOL isConnected;
@property (assign) EConnectionState connectionState;

- (IBAction) connect:(id)sender;
- (IBAction) disconnect:(id)sender;

- (IBAction) goOnline:(id)sender;
- (IBAction) goAway:(id)sender;
- (IBAction) goOffline:(id)sender;

@end
