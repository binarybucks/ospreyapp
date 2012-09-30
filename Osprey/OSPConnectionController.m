#import "OSPConnectionController.h"
#import "XMPPJID.h"
#import "XMPPStream.h"
#import "XMPPPresence.h"
#import "NSXMLElement+XMPP.h"
#import "INKeychainAccess.h"

#define ERROR_JID_NOT_SET @"JID was not set in preferences"
#define ERROR_SERVER_NOT_SET @"Server was not set in preferences"

@implementation OSPConnectionController

- (XMPPStream *) xmppStream
{
    return [[NSApp delegate] xmppStream];
}


- (OSPNotificationController *) notificationController
{
    return [[NSApp delegate] notificationController];
}


- (void) awakeFromNib
{
    [[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self clearError];

    [statusMenu setAutoenablesItems:NO];
}


- (void) addValToConnectionState:(int)connectionStateValue
{
    // Just add if not already set
    if (connectionState & connectionStateValue)
    {
        return;
    }

    [self setValue:[NSNumber numberWithInt:(connectionState + connectionStateValue)] forKey:@"connectionState"];
}


- (void) removeValFromConnectionState:(int)connectionStateValue
{
    // Just remove if already set
    if ( !(connectionState & connectionStateValue) )
    {
        return;
    }

    [self setValue:[NSNumber numberWithInt:(connectionState - connectionStateValue)] forKey:@"connectionState"];
}


#pragma mark -- Connection Management
- (IBAction) connect:(id)sender
{
    LOGFUNCTIONCALL

    NSError *error = nil;
    [self clearError];
    BOOL success;

    // Do some checks for common mistakes
    if ([XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTJID]] == nil )
    {
//        [self handleError:connectionError withErrorString:ERROR_JID_NOT_SET];
//        [[self notificationController] notificationForAuthenticationErrorWithErrorString:ERROR_JID_NOT_SET];
        [[self notificationController] notificationForUnsetAccountPreferences];
        return;
    }

    if ([XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTSERVER]] == nil )
    {
//        [[self notificationController] notificationForAuthenticationErrorWithErrorString:ERROR_JID_NOT_SET];
        [[self notificationController] notificationForUnsetAccountPreferences];
//
//        [self handleError:connectionError withErrorString:ERROR_SERVER_NOT_SET];
//        return;
    }

    if (![[self xmppStream] isConnected])
    {
        [self addValToConnectionState:connecting];

        NSString *myResource = [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTRESOURCE];
        XMPPJID *myJid = [XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTJID] resource:myResource];
        [[self xmppStream] setMyJID:myJid];
        [[self xmppStream] setHostName:[[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTSERVER]];
        [[self xmppStream] setHostPort:[[NSUserDefaults standardUserDefaults] integerForKey:STDUSRDEF_ACCOUNTPORT]];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_ACCOUNTOLDSSL])
        {
            DDLogVerbose(@"Connecting via OldSchoolSecureConnect");
            success = [[self xmppStream] oldSchoolSecureConnect:&error];
        }
        else
        {
            DDLogVerbose(@"Connecting via normal connect");
            success = [[self xmppStream] connect:&error];
        }
    }

    if (!success)
    {
        // Very early error, before even connecting, abandon ship.
        [self handleError:connectionError withErrorString:[error localizedDescription]];
        [[self xmppStream] disconnect]; // connecting state gets cleared by xmppStreamDidDisconnect method
    }

    // All following events after successfull connetions are be handled by xmppStream notifications
}


- (IBAction) disconnect:(id)sender
{
    if (connectionState & authenticated)
    {
        [self goOffline:nil];
        [[self xmppStream] disconnectAfterSending];
    }
    else
    {
        [[self xmppStream] disconnect];
    }
}


#pragma mark - Presence Management
- (NSString *) _priorityForStatus:(EStatusState)status
{
    NSString *priority;

    switch (status)
    {
        case online:
            priority = [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTONLINEPRIORITY]; break;
        case away:
            priority = [[NSUserDefaults standardUserDefaults] stringForKey:STDUSRDEF_ACCOUNTAWAYPRIORITY]; break;
        default:
            priority = @"0";
    }

    if (priority == nil)
    {
        priority = @"0";
    }

    return priority;
}


- (IBAction) goOnline:(id)sender
{
    LOGFUNCTIONCALL

    [setsOnline setState : NSOnState];
    [setsAway setState:NSOffState];

    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:online] forKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT];

    NSString *priority = [self _priorityForStatus:online];
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
    [presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:priority]];

    [[self xmppStream] sendElement:presence];
}


- (IBAction) goAway:(id)sender
{
    LOGFUNCTIONCALL

    [setsOnline setState : NSOffState];
    [setsAway setState:NSOnState];

    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:away] forKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT];

    NSString *priority = [self _priorityForStatus:away];
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];

    [presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:priority]];
    [presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"away"]];

    [[self xmppStream] sendElement:presence];
}


- (IBAction) goOffline:(id)sender
{
    LOGFUNCTIONCALL

    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}


#pragma mark XMPPStream Delegate Methods
- (void) xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    LOGFUNCTIONCALL

    if ([[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_ACCOUNTALLOWSELFSIGNEDCERTIFICATES])
    {
        [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_ACCOUNTALLOWHOSTNAMEMISMATCH])
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


- (void) xmppStreamDidSecure:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
}


- (void) xmppStreamDidConnect:(XMPPStream *)sender
{
    LOGFUNCTIONCALL

    [self removeValFromConnectionState : connecting];
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

    success = [[self xmppStream] authenticateWithPassword:[INKeychainAccess passwordForAccount:self.xmppStream.myJID.bare
                                                                                   serviceName:APP_NAME error:&authError]
                                                    error:&error];

//	}

    if (!success)
    {
        DDLogError(@"%@: %@: %@", THIS_FILE, THIS_METHOD, [error localizedDescription]);
        [self handleError:connectionError withErrorString:[error localizedDescription]];
    }
}


- (void) xmppStreamDidRegister:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
    [self removeValFromConnectionState : registering];
    [self addValToConnectionState:registered];
}


- (void) xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    LOGFUNCTIONCALL

    [self handleError : registrationError withErrorString :[[error elementForName:@"failure"] stringValue]];
    [self removeValFromConnectionState:registering];
    [[self xmppStream] disconnect];
}


- (void) xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    LOGFUNCTIONCALL
    [self removeValFromConnectionState : authenticating];
    [self addValToConnectionState:authenticated];

    EStatusState statusAfterConnect = [[[NSUserDefaults standardUserDefaults] valueForKey:STDUSRDEF_ACCOUNTSTATUSAFTERCONNECT] intValue];

    if (statusAfterConnect & online)
    {
        DDLogVerbose(@"Going online automatically");
        [self goOnline:nil];
    }
    else if (statusAfterConnect & away)
    {
        DDLogVerbose(@"Going away automatically");
        [self goAway:nil];
    }
}


- (void) xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    LOGFUNCTIONCALL

    [self removeValFromConnectionState : authenticating];
    [self removeValFromConnectionState:authenticated];

    [self handleError:authenticationError withErrorString:[[error elementForName:@"failure"] stringValue]];
    [[self xmppStream] disconnect];
}


- (void) xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    DDLogError(@"%@: %@: %@", THIS_FILE, THIS_METHOD, error);
//    if (error) {
//        [self handleError:connectionError withErrorString:[error str]];
//    }
}


- (void) xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogError(@"%@: %@: %@", THIS_FILE, THIS_METHOD, error);

    // Update tracking variables
    [self setValue:[NSNumber numberWithInt:disconnected] forKey:@"connectionState"];

    if (error)
    {
        [self handleError:connectionError withErrorString:[error localizedDescription]];
    }
}


#pragma mark - Error management
- (void) handleError:(EErrorState)state withErrorString:(NSString *)errorStr
{
    DDLogError(@"An error occured: %@", errorStr);

    // Dont override exisiting error states
    if (!errorState)
    {
        errorState = state;
        if (errorStr)
        {
            errorDescription = errorStr;
        }
        else
        {
            errorDescription = @"No detailed description provided";
        }

        switch (state)
        {
            case connectionError:
                [[self notificationController] notificationForConnectionErrorWithErrorString:errorDescription];  break;
            case authenticationError:
                [[self notificationController] notificationForAuthenticationErrorWithErrorString:errorDescription];  break;
            case registrationError:
                break;
            default:
                break;
        }
    }
}


- (void) clearError
{
    errorState = noError;
    errorDescription = @"";
}


@end
