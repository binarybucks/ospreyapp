#import <Foundation/Foundation.h>
#import "XMPPUser.h"
#import "XMPPStream.h"
#import "XMPPMessage.h"
#import "OSPChatViewController.h"
#import "OSPTableView.h"
#import "Types.h"
#import "XMPPAttentionModule.h"

@interface OSPChatController : NSObject <NSTableViewDelegate, NSWindowDelegate, XMPPAttentionDelegate>{
    NSMutableDictionary         *openChatViewControllers;
    IBOutlet NSArrayController *openChatsArrayController;
    IBOutlet OSPTableView      * openChatsTable;
    IBOutlet NSView *chatView;
    
    bool initialAwakeFromNibCallFinished;
    int summedUnreadCount;
}
@property (strong) NSMutableArray *openChatUsers;


- (void)openChatWithUser:(OSPUserStorageObject*)user;
- (void)openChatWithJid:(XMPPJID*)jid;    

- (void)closeChatWithUser:(id <XMPPUser>)user;
- (IBAction)closeSelectedChat:(id)sender;

@end
