#import <Cocoa/Cocoa.h>
#import "XMPPUserCoreDataStorageObject.h"
#import <WebKit/WebKit.h>
#import <WebKit/WebResourceLoadDelegate.h>
#import <WebKit/WebFrameLoadDelegate.h>

@interface OSPChatViewController : NSViewController {
    IBOutlet NSTextField    *inputField;
    IBOutlet WebView        *webView;
    IBOutlet NSWindow       *window;
    
    XMPPJID *localJid;
    XMPPJID *remoteJid;
    XMPPJID *lastMessageFromJid;
    DOMHTMLElement *streakElement;
 
    NSMutableArray *messageQueue;
    
    BOOL isLoadViewFinished;
    BOOL isWebViewReady;
    
    dispatch_queue_t processingQueue;

}

- (id)initWithRemoteJid:(XMPPJID*)rjid;
- (void) focusInputField;
- (IBAction) send:(id)sender;
- (void) receive:(XMPPMessage*)message;


- (void) displayChatMessage:(XMPPMessage*)message;
- (void) displayAttentionMessage:(XMPPMessage*)message;
- (void) displayPresenceMessage:(XMPPPresence*)message;
- (void) display:(NSXMLElement*)object withKind:(NSString*)kind;

@end
