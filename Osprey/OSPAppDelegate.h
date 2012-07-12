#import <Cocoa/Cocoa.h>
#import "OSPChatController.h"
#import "OSPRosterController.h"
#import "OSPStatusController.h"
#import "INAppStoreWindow.h"

#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPResourceCoreDataStorageObject.h"
#import "XMPPPing.h"
#import "XMPPTime.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPvCardTemp.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPRoster.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPAttentionModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "DDTTYLogger.h"
#import "OSPNotificationController.h"
#import "OSPRosterController.h"
#import "INPopoverController.h"

@interface OSPAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, INPopoverControllerDelegate> {
    XMPPStream                          *xmppStream;
	XMPPReconnect                       *xmppReconnect;
    XMPPRoster                          *xmppRoster;
    XMPPRosterCoreDataStorage           *xmppRosterStorage;
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
    OSPNotificationController           *notificationController;
    
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
@property (weak)    IBOutlet OSPStatusController        *statusController;

- (IBAction)togglePopover:(id)sender;

@end
