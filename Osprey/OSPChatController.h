#import <Foundation/Foundation.h>
#import "XMPPUser.h"
#import "XMPPStream.h"
#import "XMPPMessage.h"
#import "OSPChatViewController.h"
#import "OSPTableView.h"
#import "Types.h"
#import "XMPPAttentionModule.h"
#import "OSPChatCoreDataStorage.h"

@interface OSPChatController : NSObject <NSTableViewDelegate, NSWindowDelegate, XMPPAttentionDelegate>{
    IBOutlet OSPTableView       * openChatsTable;
    IBOutlet NSView             *chatView;

    NSMutableDictionary         *openChatViewControllers;
    NSArray                     *openChats;
    IBOutlet NSArrayController           *openChatsArrayController;
    OSPChatCoreDataStorage      *openChatsStorage;
    NSManagedObjectContext      *openChatsMoc;
    
    
    bool initialAwakeFromNibCallFinished;
    int summedUnreadCount;
}
@property (strong) NSMutableArray *openChatUsers;
@property (strong, readonly) NSManagedObjectContext *openChatsMoc;


- (void)openChatWithUser:(OSPUserStorageObject*)user;
- (void)openChatWithJid:(XMPPJID*)jid;    

- (void)closeChatWithUser:(id <XMPPUser>)user;
- (IBAction)closeSelectedChat:(id)sender;

@end
