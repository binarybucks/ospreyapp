#import <Cocoa/Cocoa.h>
#import "Types.h"

@interface OSPStatusController : NSObject {
    BOOL useSSL;
    BOOL allowSelfSignedCertificates;
    BOOL allowSSLHostNameMismatch;

    BOOL isRegistering;
    BOOL isAuthenticating;
    BOOL isAuthenticated;
    BOOL isConnected;
    BOOL hasError;

    IBOutlet NSMenuItem *offlineMenuItem;
    IBOutlet NSMenuItem *onlineMenuItem;

    IBOutlet NSMenuItem *connectionStateIndicator;
    IBOutlet NSMenuItem *setsOnline;
    IBOutlet NSMenuItem *setsAway;
    IBOutlet NSMenu     *statusMenu;
    IBOutlet NSWindow   *window;

    EErrorState         errorState;
    EConnectionState    connectionState;
    NSString            *errorDescription;
}

@property (assign) BOOL isConnected;
@property (assign) EConnectionState connectionState;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;

- (IBAction)goOnline:(id)sender;
- (IBAction)goAway:(id)sender;
- (IBAction)goOffline:(id)sender;
- (IBAction)displayErrorSheet:(id)sender;



@end
