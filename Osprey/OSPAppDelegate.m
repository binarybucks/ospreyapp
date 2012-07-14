#import "OSPAppDelegate.h"
#import "NSColor+HexAdditions.h"

@interface OSPAppDelegate (PrivateApi)
-(void)_arrange:(NSView*)view accordingTo:(NSView*)splitViewView;
- (void)_mocDidChange:(NSNotification *)notification;

@end

@implementation OSPAppDelegate

@synthesize window = _window;

@synthesize chatController;
@synthesize statusController;
@synthesize xmppvCardAvatarModule;
@synthesize xmppvCardTempModule;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize xmppPing;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize managedObjectContext;
@synthesize xmppAttentionModule;
- (id)init
{
	if ((self = [super init]))
	{
		// Configure logging framework
		[DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        // Intialize controllers that are not loaded from NIB
        rosterController =          [[OSPRosterController alloc] initWithNibName:@"rosterView" bundle:nil];
        popoverController =         [[INPopoverController alloc] initWithContentViewController:rosterController];
        notificationController =    [[OSPNotificationController alloc] init];

		// Initialize XMPP modules
		xmppStream =                [[XMPPStream alloc] init];
        xmppReconnect =             [[XMPPReconnect alloc] init];
        xmppRosterStorage =         [[OSPRosterStorage alloc] init];
        xmppRoster =                [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
        xmppCapabilitiesStorage =   [XMPPCapabilitiesCoreDataStorage sharedInstance];
        xmppCapabilities =          [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
        xmppvCardTempModule =       [[XMPPvCardTempModule alloc] initWithvCardStorage:[XMPPvCardCoreDataStorage sharedInstance]];
        xmppvCardAvatarModule =     [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
        xmppPing =                  [[XMPPPing alloc] init];
        xmppTime =                  [[XMPPTime alloc] init];
		turnSockets =               [[NSMutableArray alloc] init];
        xmppAttentionModule =       [[XMPPAttentionModule alloc] init];
    
        // Configure XMPP modules
        [xmppCapabilities setAutoFetchHashedCapabilities:YES];
        [xmppCapabilities setAutoFetchNonHashedCapabilities:NO];
        [xmppRoster setAutoFetchRoster:YES];
        [xmppRoster setAutoAcceptKnownPresenceSubscriptionRequests:YES];        
        
        // Activate XMPP modules
        [xmppReconnect activate:xmppStream];
		[xmppRoster activate:xmppStream];
		[xmppCapabilities activate:xmppStream];
		[xmppPing activate:xmppStream];
		[xmppTime activate:xmppStream];
        [xmppvCardTempModule   activate:xmppStream];
        [xmppvCardAvatarModule activate:xmppStream];
        [xmppAttentionModule activate:xmppStream];
        
        // Set up delegates        
        [xmppvCardAvatarModule addDelegate:xmppRoster delegateQueue:xmppRoster.moduleQueue];
        
        // Create threadsave managed object context for gui
        NSPersistentStoreCoordinator *coordinator = [xmppRosterStorage persistentStoreCoordinator];
        assert(coordinator);        
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
        [managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy    ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidChange:) name:NSManagedObjectContextDidSaveNotification object:nil];

    
        // Set register preferences defaults 
        NSDictionary *userDefaultsDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @"Osprey", STDUSRDEF_ACCOUNTRESOURCE,
                                              [NSNumber numberWithInt:5222], STDUSRDEF_ACCOUNTPORT,
                                              [NSNumber numberWithBool:NO], STDUSRDEF_ACCOUNTOLDSSL,
                                              [NSNumber numberWithInt:online], STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT,
                                              [NSNumber numberWithInt:24], STDUSRDEF_ACCOUNTONLINEPRIORITY,
                                              [NSNumber numberWithInt:0], STDUSRDEF_ACCOUNTAWAYPRIORITY,
                                              [NSNumber numberWithBool:YES], STDUSRDEF_GENERALDISPLAYGROWLNOTIFICATIONS,
                                              [NSNumber numberWithBool:NO], STDUSRDEF_GENERALCONNECTONSTARTUP,
                                              nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];

    }
    
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    
    
    //  Set height of titlebar and center traffic lights
    ((INAppStoreWindow*)self.window).centerFullScreenButton = YES;
    ((INAppStoreWindow*)self.window).titleBarHeight = 40;
    
    // Set style of roster button
    [[rosterPopoverButton cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [rosterPopoverButton setImage:[NSImage imageNamed:@"plus"]];

    // Add views to titlebar and set initial position 
    toolbarRightView.frame = self.window.titleBarView.bounds;
    toolbarRightView.autoresizingMask = NSViewWidthSizable;
    [self.window.titleBarView addSubview:toolbarRightView];
        
    // Configure popover behaviour
    popoverController.closesWhenPopoverResignsKey = YES;
    popoverController.closesWhenApplicationBecomesInactive = NO;
    [popoverController setDelegate:self];

}

- (void)_mocDidChange:(NSNotification *)notification {
    NSManagedObjectContext *sender = (NSManagedObjectContext *)[notification object];
    
    if (sender != managedObjectContext &&
        [sender persistentStoreCoordinator] == [managedObjectContext persistentStoreCoordinator])
    {
        [managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                               withObject:notification
                                            waitUntilDone:YES];        
    }
}

- (IBAction)togglePopover:(id)sender
{
    [popoverController presentPopoverFromRect:[rosterPopoverButton frame] inView:[rosterPopoverButton superview] preferredArrowDirection:INPopoverArrowDirectionDown anchorsToPositionView:YES];
}

- (void)popoverDidShow:(INPopoverController*)popover {
    [rosterController.searchField becomeFirstResponder];
}

@end