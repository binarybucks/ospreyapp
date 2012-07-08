#import "OSPChatViewController.h"
#import "NSColor+HexAdditions.h"
#import "Types.h"
#import "XMPPMessage+XEP_0224.h"

typedef enum {
    localToRemote = 1, 
    remoteToLocal = 2,
} EDirection;

@interface OSPChatViewController (PrivateAPI) 
- (NSImage*) _avatarForJid:(XMPPJID*)jid;
- (void) _writeToTextView:(NSString*)message forJid:(XMPPJID*)jid;
- (void) _displayPresenceMessage:(XMPPPresence*)presence;
- (void) _displayAttentionMessage:(XMPPMessage*)message;
- (void) _displayChatMessage:(XMPPMessage*)message;

@end


@implementation OSPChatViewController

#pragma mark -  Accessors
- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

- (OSPRosterController *)rosterController
{
	return [[NSApp delegate] rosterController];
}

- (XMPPRoster *)xmppRoster
{
	return [[NSApp delegate] xmppRoster];
}

- (OSPRosterStorage *)xmppRosterStorage
{
	return [[NSApp delegate] xmppRosterStorage];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

#pragma mark - Intialization
- (id)initWithRemoteJid:(XMPPJID*)rjid
{
    self = [super initWithNibName:@"chatView" bundle:nil];
    if (self) {
        isLoadViewFinished = NO;
        isWebViewReady = NO;
        localJid = [[self xmppStream] myJID];
        remoteJid = rjid;
        messageQueue = [[NSMutableArray alloc] init];
        
        
        
        processingQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
        dispatch_suspend(processingQueue);

    }
    return self;
    
}

- (void) dealloc {
    dispatch_release(processingQueue);


}

- (void) awakeFromNib {
    [inputField bind:@"hidden" toObject:[[NSApp delegate] statusController] withKeyPath:@"connectionState" options:[NSDictionary dictionaryWithObjectsAndKeys:@"CNVConnectionStateToNotAuthenticatedTransformer",NSValueTransformerNameBindingOption, nil]];
}



- (void)cstmviewWillLoad {
    
}

- (void)cstmviewDidLoad {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"chat" withExtension:@"html"];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)loadView {
    if (!isLoadViewFinished) {
        [self cstmviewWillLoad];
        [super loadView];
        [self cstmviewDidLoad];
        isLoadViewFinished = YES;
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSLog(@"resuming queue");
    isWebViewReady = YES;
    dispatch_resume(processingQueue);
}









- (void) focusInputField {
    [inputField becomeFirstResponder];
}




# pragma mark - Message display 

// Convenience accessors to processing queue
- (void) displayChatMessage:(XMPPMessage*)message {
    [self display:message withKind:@"Chat"];
}
- (void) displayAttentionMessage:(XMPPMessage*)message {
    [self display:message withKind:@"Attention"];
}
- (void) displayPresenceMessage:(XMPPPresence*)message {
    [self display:message withKind:@"Presence"];    
}

// Processing queue scheduler
- (void) display:(NSXMLElement*)object withKind:(NSString*)kind {
    NSLog(@"Kind: %@", kind);
    dispatch_block_t block = ^{ @autoreleasepool {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_display%@Message:", kind]);
        if ([self respondsToSelector:selector]) {
            dispatch_async(dispatch_get_main_queue(), ^{  
                [self performSelector:selector withObject:object];
            });
        }
    }};
	
	if (isWebViewReady) {  block(); } 
    else { self.loadView; dispatch_async(processingQueue, block); }    
}

// Private methods for actual display. 
// Never call from outside as corresponding webView might not be ready.
- (void) _displayChatMessage:(XMPPMessage*)message {
    XMPPJID *fromJID = [[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]] bareJID]; 
    DOMHTMLElement *messageElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    DOMHTMLElement *datetime = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"span"];
    [datetime setAttribute:@"class" value:@"datetime"];
    [datetime setInnerText:[formatter stringFromDate:[NSDate date]]];
    
    // Check if we have an inbound or outbound message
    NSString *inOut = [fromJID isEqualToJID:remoteJid] ? @"in" : @"out";
    
    
    // Check if message is in a streak
    if ((![fromJID isEqualToJID:lastMessageFromJid]) || (streakElement == nil)) {
        streakElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
        [streakElement setAttribute:@"class" value:[NSString stringWithFormat:@"streak %@", inOut]]; 
        [[[[webView mainFrame] DOMDocument] getElementById:@"chat"] appendChild:streakElement];
    }
    
    [messageElement setAttribute:@"class" value:[NSString stringWithFormat:@"message %@", inOut]];    
    [messageElement setInnerHTML:[NSString stringWithFormat:@"%@", [[message elementForName:@"body"] stringValue]]];
    [messageElement appendChild:datetime];
    lastMessageFromJid = fromJID;
    
    [streakElement appendChild:messageElement];
    [messageElement scrollIntoView:YES];
}

- (void) _displayAttentionMessage:(XMPPMessage*)message {
    XMPPJID *fromJID = [[XMPPJID jidWithString:[message attributeStringValueForName:@"from"]] bareJID]; 
    DOMHTMLElement *messageElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];

    streakElement = (DOMHTMLElement*)[[[webView mainFrame] DOMDocument] createElement:@"div"];
    [streakElement setAttribute:@"class" value:@"streak attention"]; 
    [[[[webView mainFrame] DOMDocument] getElementById:@"chat"] appendChild:streakElement];
    
    [messageElement setAttribute:@"class" value:[NSString stringWithFormat:@"message"]];    
    [messageElement setInnerHTML:[NSString stringWithFormat:@"Your contact %@", [[message elementForName:@"body"] stringValue]]];

    lastMessageFromJid = nil;

    [streakElement appendChild:messageElement];
    [messageElement scrollIntoView:YES];
}

- (void) _displayPresenceMessage:(XMPPPresence*)presence {
    
}
// Takes input from the user, sends it and enques for display
- (IBAction) send:(id)sender {
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:remoteJid];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:[sender stringValue]];
    [message addChild:body];
    
    [[self xmppStream] sendElement:message];
    [message addAttributeWithName:@"from" stringValue:[localJid full]];
    
    [self displayChatMessage:message];
    
    [sender setStringValue:@""];
}



- (NSImage*) _avatarForJid:(XMPPJID*)jid {
    OSPUserStorageObject *user = [[self xmppRosterStorage] userForJID:jid xmppStream:[self xmppStream] managedObjectContext:[self managedObjectContext]];
    
    NSImage *avatar;
    
    assert(user); // Not sure if the own user is always contained in the roster
    
    // If the photo is cached in the roster, use that, otherwise get it from vCardAvatarModule
    if (user.photo != nil)
	{
		avatar = user.photo;
	} 
	else
	{
        NSData *photoData = [[[NSApp delegate] xmppvCardAvatarModule] photoDataForJID:jid];
        if (photoData != nil) {
            avatar = [[NSImage alloc] initWithData:photoData];
            user.photo = avatar; // Cache it in roster while we're at it
        } else { 
            avatar = [NSImage imageNamed:@"Account"];
        }
    }
    
    [avatar setSize:NSMakeSize(38.0, 38.0)];
    return avatar;
}

@end
