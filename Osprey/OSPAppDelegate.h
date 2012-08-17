#import "XMPPFramework.h"


#import "OSPChatController.h"
#import "OSPRosterController.h"
#import "OSPNotificationController.h"
#import "OSPConnectionController.h"
#import "OSPPreferencesController.h"

#import "INAppStoreWindow.h"
#import "INPopoverController.h"


@interface OSPAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, INPopoverControllerDelegate> {
    XMPPStream                          *xmppStream;
	XMPPReconnect                       *xmppReconnect;
    XMPPRoster                          *xmppRoster;
    OSPRosterStorage                    *xmppRosterStorage;
    NSManagedObjectContext              *managedObjectContext;
    XMPPPing                            *xmppPing;
	XMPPTime                            *xmppTime;
	XMPPCapabilities                    *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage     *xmppCapabilitiesStorage;
    XMPPvCardAvatarModule               *xmppvCardAvatarModule;
    XMPPvCardTempModule                 *xmppvCardTempModule;
    XMPPAttentionModule                 *xmppAttentionModule;
	NSMutableArray                      *turnSockets;
    
    OSPRosterController                 *rosterController;
    
    INPopoverController                 *popoverController;
    IBOutlet NSPopover                  *rosterPopover;
    IBOutlet NSButton                   *rosterPopoverButton;
    IBOutlet NSView                     *toolbarRightView;
    IBOutlet NSSplitView                *splitView;
}

@property (nonatomic, readonly) XMPPvCardAvatarModule               *xmppvCardAvatarModule;
@property (nonatomic, readonly) XMPPvCardTempModule                 *xmppvCardTempModule;
@property (nonatomic, readonly) XMPPStream                          *xmppStream;
@property (nonatomic, readonly) XMPPReconnect                       *xmppReconnect;
@property (nonatomic, readonly) XMPPCapabilities                    *xmppCapabilities;
@property (nonatomic, readonly) XMPPCapabilitiesCoreDataStorage     *xmppCapabilitiesStorage;
@property (nonatomic, readonly) XMPPPing                            *xmppPing;
@property (nonatomic, readonly) XMPPRoster                          *xmppRoster;
@property (nonatomic, readonly) XMPPAttentionModule                 *xmppAttentionModule;
@property (nonatomic, readonly) XMPPRosterCoreDataStorage           *xmppRosterStorage;
@property (nonatomic, readonly) NSManagedObjectContext              *managedObjectContext;

@property (assign)  IBOutlet INAppStoreWindow           *window;
@property (weak)    IBOutlet OSPChatController          *chatController;
@property (weak)    IBOutlet OSPConnectionController        *connectionController;
@property (weak)    IBOutlet OSPNotificationController *notificationController;
@property (weak)    IBOutlet OSPPreferencesController *preferencesController;

- (void)closeRosterPopover;
- (IBAction)openRosterPopover:(id)sender;

@end
