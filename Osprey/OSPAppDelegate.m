#import "OSPAppDelegate.h"

@implementation OSPAppDelegate

- (id)init
{
	if ((self = [super init]))
	{
        
        
		// Configure logging framework
		[DDLog addLogger:[DDTTYLogger sharedInstance]];
        NSLog(@"Starting %@ build %@", APP_NAME, [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"]);
        NSLog(@"This release was compiled with log-level %d", ddLogLevel);
        NSLog(@"This is an very early release. Please fill bugs, crashes and other rants at http://github.com/binarybucks/ospreyapp/issues");
        
        // Register preferences defaults 
        NSDictionary *userDefaultsDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                              APP_NAME, STDUSRDEF_ACCOUNTRESOURCE,
                                              [NSNumber numberWithInt:5222], STDUSRDEF_ACCOUNTPORT,
                                              [NSNumber numberWithBool:NO], STDUSRDEF_ACCOUNTOLDSSL,
                                              [NSNumber numberWithInt:online], STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT,
                                              [NSNumber numberWithInt:24], STDUSRDEF_ACCOUNTONLINEPRIORITY,
                                              [NSNumber numberWithInt:0], STDUSRDEF_ACCOUNTAWAYPRIORITY,
                                              [NSNumber numberWithBool:YES], STDUSRDEF_GENERALDISPLAYGROWLNOTIFICATIONS,
                                              [NSNumber numberWithBool:NO], STDUSRDEF_GENERALCONNECTONSTARTUP,
                                              nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];

        
        // Intialize controllers that are not loaded from NIB
        _rosterController =          [[OSPRosterController alloc] initWithNibName:@"rosterView" bundle:nil];
        popoverController =         [[INPopoverController alloc] initWithContentViewController:_rosterController];

		// Initialize XMPP modules and datastores
		_xmppStream =                [[XMPPStream alloc] init];
        _xmppReconnectModule =             [[XMPPReconnect alloc] init];
        _xmppRosterStorage =         [[OSPRosterStorage alloc] initWithDatabaseFilename:@"OSPRoster.sqlite"];
        _xmppRosterModule =                [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
        _xmppCapabilitiesStorage =   [[XMPPCapabilitiesCoreDataStorage alloc] initWithDatabaseFilename:@"OSPCapabilities.sqlite"];
        _xmppCapabilitiesModule =          [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
        _xmppvCardTempModule =       [[XMPPvCardTempModule alloc] initWithvCardStorage:[[XMPPvCardCoreDataStorage alloc] initWithDatabaseFilename:@"OSPVCard.sqlite"]];
        
        
        _xmppvCardAvatarModule =     [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
        _xmppPingModule =                  [[XMPPPing alloc] init];
        _xmppTimeModule =                  [[XMPPTime alloc] init];
		turnSockets =               [[NSMutableArray alloc] init];
        _xmppAttentionModule =       [[XMPPAttentionModule alloc] init];
        _xmppMessageArchivingCoreDataStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
        _xmppMessageArchivingModule = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage];
        
        // Configure XMPP modules
        [_xmppCapabilitiesModule setAutoFetchHashedCapabilities:YES];
        [_xmppCapabilitiesModule setAutoFetchNonHashedCapabilities:NO];
        [_xmppRosterModule setAutoFetchRoster:YES];
        [_xmppRosterModule setAutoAcceptKnownPresenceSubscriptionRequests:YES];
        
        // Activate XMPP modules
        [_xmppReconnectModule activate:_xmppStream];
		[_xmppRosterModule activate:_xmppStream];
		[_xmppCapabilitiesModule activate:_xmppStream];
		[_xmppPingModule activate:_xmppStream];
		[_xmppTimeModule activate:_xmppStream];
        [_xmppvCardTempModule   activate:_xmppStream];
        [_xmppvCardAvatarModule activate:_xmppStream];
        [_xmppAttentionModule activate:_xmppStream];
        // [xmppChatStateNotificationModule activate:xmppStream];
        
        // We start with a clean roster for now
        [_xmppRosterStorage clearAllUsersAndResourcesForXMPPStream:_xmppStream]; 
        _managedObjectContext = [_xmppRosterStorage mainThreadManagedObjectContext];

        // Set up delegates
        [_xmppvCardAvatarModule addDelegate:_xmppRosterModule delegateQueue:_xmppRosterModule.moduleQueue];
        


    }
    
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserNotification *launchNotification = [[aNotification userInfo]
                                              objectForKey:NSApplicationLaunchUserNotificationKey];
    if (launchNotification) {
        // application was launched by a user selection from Notification Center
    }

    
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

    if ([[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_GENERALCONNECTONSTARTUP]) {
        [self.connectionController connect:nil];
    }
}

// popover should probably be hanled by the rosterController
- (void)closeRosterPopover {
        [popoverController closePopover:rosterPopover];
    }

- (IBAction)openRosterPopover:(id)sender {
    [popoverController presentPopoverFromRect:[rosterPopoverButton frame] inView:[rosterPopoverButton superview] preferredArrowDirection:INPopoverArrowDirectionDown anchorsToPositionView:YES];
}

- (void)popoverDidShow:(INPopoverController*)popover {
    [_rosterController.searchField becomeFirstResponder];
}

@end
