#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <WebKit/WebResourceLoadDelegate.h>
#import <WebKit/WebFrameLoadDelegate.h>

@interface OSPChatViewController : NSViewController<NSControlTextEditingDelegate, NSTableViewDelegate>   {
    IBOutlet NSTextField    *inputField;
//    IBOutlet WebView        *webView;
    IBOutlet NSWindow       *window;
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSScrollView *scrollView;
    IBOutlet NSTableColumn *messageTableColumn;
    IBOutlet NSTableView *tableView;

    XMPPJID *localJid;
    XMPPJID *remoteJid;
    XMPPJID *lastMessageFromJid;
    DOMHTMLElement *streakElement;
    NSMutableDictionary *cachedUsernames;
 
//    NSMutableArray *messageQueue;
    
//    BOOL isLoadViewFinished;
//    BOOL isWebViewReady;
    
//    dispatch_queue_t processingQueue;
//    BOOL processionQueueIsSuspended;
    NSTimer *inputTimer;
    BOOL typing;

}

- (id)initWithRemoteJid:(XMPPJID*)rjid;
- (void) focusInputField;
- (IBAction) send:(id)sender;


//- (void) displayChatMessage:(XMPPMessage*)message;
//- (void) displayAttentionMessage:(XMPPMessage*)message;
//- (void) displayPresenceMessage:(XMPPPresence*)message;
//- (void) dispatch:(NSXMLElement*)object toSelector:(SEL)selector;

@end
