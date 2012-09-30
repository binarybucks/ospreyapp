#import "XMPPFramework.h"

#import "OSPChatController.h"
#import "OSPRosterController.h"
#import "OSPNotificationController.h"
#import "OSPConnectionController.h"
#import "OSPPreferencesController.h"

#import "INAppStoreWindow.h"
#import "INPopoverController.h"

@interface OSPAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, INPopoverControllerDelegate> {
    NSMutableArray *turnSockets;
    INPopoverController *popoverController;

    IBOutlet NSPopover *rosterPopover;
    IBOutlet NSButton *rosterPopoverButton;
    IBOutlet NSView *toolbarRightView;
    IBOutlet NSSplitView *splitView;
}

// Modules
@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, readonly) XMPPReconnect *xmppReconnectModule;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilitiesModule;
@property (nonatomic, readonly) XMPPPing *xmppPingModule;
@property (nonatomic, readonly) XMPPRoster *xmppRosterModule;
@property (nonatomic, readonly) XMPPAttentionModule *xmppAttentionModule;
@property (nonatomic, readonly) XMPPMessageArchiving *xmppMessageArchivingModule;
@property (nonatomic, readonly) XMPPTime *xmppTimeModule;
@property (nonatomic, readonly) XMPPPing *xmppPing;

// Datastores
@property (nonatomic, readonly) OSPRosterStorage *xmppRosterStorage;
@property (nonatomic, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, readonly) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectContext *messagesStoreMainThreadManagedObjectContext;

// Controller
@property (assign)  IBOutlet INAppStoreWindow *window;
@property (weak)    IBOutlet OSPChatController *chatController;
@property (weak)    IBOutlet OSPConnectionController *connectionController;
@property (weak)    IBOutlet OSPNotificationController *notificationController;
@property (weak)    IBOutlet OSPPreferencesController *preferencesController;
@property (strong)  IBOutlet OSPRosterController *rosterController;

- (void) closeRosterPopover;
- (IBAction) openRosterPopover:(id)sender;

@end
