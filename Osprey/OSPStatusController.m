#import "OSPStatusController.h"
#import "XMPPJID.h"
#import "XMPPStream.h"
#import "XMPPPresence.h"
#import "NSXMLElement+XMPP.h"
#import "INKeychainAccess.h"

@interface OSPStatusController (PrivateAPI)
- (NSString*)_priorityForStatus:(EStatusState)status;
@end

@implementation OSPStatusController

@synthesize isConnected;
@synthesize connectionState;

- (void)anErrorOccured:(EErrorState)state withErrorString:(NSString*)errorStr {
    LOGFUNCTIONCALL
    NSLog(@"Error: %@", errorStr);
    // Dont override exisiting error states
    if (!errorState) {
        [self setValue:[NSNumber numberWithBool: YES] forKey:@"hasError"];
        errorState = state;
        if (errorStr) {
            errorDescription = errorStr;
        } else {
            errorDescription = @"No detailed description provided";
        }
    }
}   

- (void)clearError {
    [self setValue:[NSNumber numberWithBool: NO] forKey:@"hasError"];
    errorState = noError;
    errorDescription = @"";
}

- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}
- (id)init
{   
    LOGFUNCTIONCALL
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib
{
    LOGFUNCTIONCALL    
    [self clearError];
	[[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [statusMenu setAutoenablesItems:NO];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"General.ConnectOnStartup"]) {
        [self connect:nil];
    }
}

- (void)addValToConnectionState:(int)connectionStateValue {
    
    // Just add if not already set
    if (connectionState & connectionStateValue) {
        DDLogVerbose(@"Not adding connectionState %d because it is already contained in %d", connectionStateValue, connectionState);
        return;
    }
    
    [self setValue:[NSNumber numberWithInt:(connectionState+connectionStateValue)] forKey:@"connectionState"];
}

- (void)removeValFromConnectionState:(int)connectionStateValue {
    
    // Just remove if already set
    if (! (connectionState & connectionStateValue)) {
        DDLogVerbose(@"Not removing connectionState %d because it is not contained in %d", connectionStateValue, connectionState);
        return;
    }
    
    [self setValue:[NSNumber numberWithInt:(connectionState-connectionStateValue)] forKey:@"connectionState"];
}




#pragma mark --
#pragma mark Connection Management
- (IBAction)connect:(id)sender
{	
    LOGFUNCTIONCALL     
    
    NSError *error = nil;
    [self clearError];
    BOOL success;
    
    if(![[self xmppStream] isConnected])
    {
        [self addValToConnectionState:connecting];
        [NSNotificationCenter didChangeValueForKey:@"connectionState"];
        
        NSString *myResource = [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTRESOURCE];
        XMPPJID *myJid = [XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTJID] resource:myResource];
        [[self xmppStream] setMyJID:myJid];
        [[self xmppStream] setHostName:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTSERVER]];    
        [[self xmppStream] setHostPort:[[NSUserDefaults standardUserDefaults] integerForKey:STDUSRDEF_ACCOUNTPORT]];
        
        
		if ([[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_ACCOUNTOLDSSL])
        {    
            DDLogVerbose(@"Connecting via OldSchoolSecureConnect");
			success = [[self xmppStream] oldSchoolSecureConnect:&error];
            
        } else {
            DDLogVerbose(@"Connecting via normal connect");
			success = [[self xmppStream] connect:&error];
            
        }
    }
    
    // Actions after successfull connetions should be handled by notifications
	if (!success)
    {        
        DDLogError(@"%@", [error localizedDescription]);
    }
    
}
- (IBAction)disconnect:(id)sender {
    [self goOffline:nil];
    [[self xmppStream] disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Presence Management
//////////////////////////////////////////////////// ////////////////////////////////////////////////////////////////////

- (NSString*)_priorityForStatus:(EStatusState)status {
    NSString *priority;
    
    switch (status) {
        case online: priority = [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTONLINEPRIORITY];break;
        case away: priority =  [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTAWAYPRIORITY];break;
        default: priority = @"0";
    }
                          
    if (priority == nil) {
        priority = @"0";
    }
    return priority;
}

- (IBAction)goOnline:(id)sender {
    LOGFUNCTIONCALL
    
    [setsOnline setState:NSOnState];
    [setsAway setState:NSOffState];

    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:online] forKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT];

    NSString *priority = [self _priorityForStatus:online];      
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
    [presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:priority]];

    [[self xmppStream] sendElement:presence];
}
- (IBAction)goAway:(id)sender {
    LOGFUNCTIONCALL
    
    [setsOnline setState:NSOffState];
    [setsAway setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:away] forKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT];
        
    NSString *priority = [self _priorityForStatus:away];    
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
    
    [presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:priority]];
    [presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"away"]];    
    
    [[self xmppStream] sendElement:presence];
    
}
- (IBAction)goOffline:(id)sender {
    LOGFUNCTIONCALL
    
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

#pragma mark XMPPStream Delegate Methods
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    LOGFUNCTIONCALL
    
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverHostName = [sender hostName];
		NSString *virtualHostName = [[sender myJID] domain];
		
		if ([serverHostName isEqualToString:@"talk.google.com"])
		{
			if ([virtualHostName isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualHostName;
			}
			else
			{
				expectedCertName = serverHostName;
			}
		}
		else
		{
			expectedCertName = serverHostName;
		}
		
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
}
- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
}



- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
    [self setValue:[NSNumber numberWithBool: YES] forKey:@"isConnected"];
    
    [self removeValFromConnectionState:connecting];
    [self addValToConnectionState:connected];
    
    
    [self clearError];
    
	NSError *error = nil;
    NSError *authError = nil;

	BOOL success;

	
//  Registration is not yet possible
//	if(shallRegister)
//	{
//        [self addValToConnectionState:registering];
//		success = [[self xmppStream] registerWithPassword:[[PDKeychainBindingsController sharedKeychainBindingsController] stringForKey:@"AccountPassword"] error:&error];
//    }
//	else
//	{
    [self addValToConnectionState:authenticating];
    
    //    + (NSString*)passwordForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error;

    success = [[self xmppStream] authenticateWithPassword:[INKeychainAccess passwordForAccount:self.xmppStream.myJID.bare serviceName:APP_NAME error:&authError] error:&error];

//	}
	
	if (!success)
	{
        DDLogError(@"%@: %@: %@", THIS_FILE, THIS_METHOD, [error localizedDescription]);
        [self anErrorOccured:connectionError withErrorString:[error localizedDescription]];
    }
}
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
    [self removeValFromConnectionState:registering];
    [self addValToConnectionState:registered];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    LOGFUNCTIONCALL
    
    [self anErrorOccured:registrationError withErrorString:[[error elementForName:@"failure"] stringValue]];
    [self removeValFromConnectionState:registering];    
	[[self xmppStream] disconnect];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
    [self removeValFromConnectionState:authenticating];
    [self addValToConnectionState:authenticated];
        
    EStatusState statusAfterConnect = [[[NSUserDefaults standardUserDefaults] valueForKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT] intValue];

    if (statusAfterConnect & online) {
        DDLogVerbose(@"Going online automatically");
        [self goOnline:nil];
    } else if (statusAfterConnect & away) {
        DDLogVerbose(@"Going away automatically");
        [self goAway:nil];
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    LOGFUNCTIONCALL
        
    [self removeValFromConnectionState:authenticating];
    [self removeValFromConnectionState:authenticated];
    
    [self anErrorOccured:authenticationError withErrorString:[[error elementForName:@"failure"] stringValue]];
    [[self xmppStream] disconnect];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{    
	DDLogError(@"%@: %@: %@", THIS_FILE, THIS_METHOD, error);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{ 
    LOGFUNCTIONCALL
    
	// Update tracking variables
    [self removeValFromConnectionState:connecting];
    [self removeValFromConnectionState:connected];
    [self removeValFromConnectionState:registering];
    [self removeValFromConnectionState:registered];
    [self removeValFromConnectionState:authenticating];
    [self removeValFromConnectionState:authenticated];
    [self addValToConnectionState:disconnected];
    
    [self setValue:[NSNumber numberWithBool: NO] forKey:@"isConnected"];
    [self setValue:[NSNumber numberWithBool: NO] forKey:@"isRegistering"];
    [self setValue:[NSNumber numberWithBool: NO] forKey:@"isAuthenticating"];
    [self setValue:[NSNumber numberWithBool: NO] forKey:@"isAuthenticated"];
    
    
    if (error) {
        [self anErrorOccured:connectionError withErrorString:[error localizedDescription]];
    }
}

- (IBAction)displayErrorSheet:(id)sender {
    if (errorState) {
        NSLog(@"state in errorsheet: %d", errorState);
        SEL sel = @selector(sheetClosed:returnCode:contextInfo:);
        NSString *title;
        
        switch (errorState) {
            case 1  : title = @"Connection Error";  break;
            case 2  : title = @"Authentication Error"; break;
            case 3  : title = @"Registration Error"; break;
            default : title = @""; break;
        }
        NSBeginAlertSheet(@"Title", @"Ok", NULL, NULL, window, self, sel, NULL, nil, errorDescription, nil);        
    } else {
        DDLogError(@"Error sheet should be shown when there was no error");
    }
}

- (void)sheetClosed:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSLog(@"Default return");
    }
}
@end
