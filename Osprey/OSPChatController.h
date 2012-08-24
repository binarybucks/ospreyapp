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
    IBOutlet OSPTableView       *openChatsTable;
    IBOutlet NSView             *chatView;
    IBOutlet NSArrayController  *openChatsArrayController;

    NSMutableDictionary         *openChatViewControllers;
    OSPChatCoreDataStorage      *openChatsStorage;
    NSManagedObjectContext      *openChatsMoc;
    
    OSPChatStorageObject *activeChat;

    bool initialAwakeFromNibCallFinished;
    int summedUnreadCount;
}
@property (strong, readonly) NSManagedObjectContext *openChatsMoc;

- (OSPChatStorageObject*)openChatWithUser:(OSPUserStorageObject*)user andMakeActive:(BOOL)makeActive;
- (OSPChatStorageObject*)openChatWithJidStr:(NSString*)jidStr andMakeActive:(BOOL)makeActive;
- (void)openChatWithStoredChat:(OSPChatCoreDataStorageObject*)chatStorageObject andMakeActive:(BOOL)makeActive;

- (void)closeChat:(OSPChatCoreDataStorageObject*)chat;
- (IBAction)closeSelectedChat:(id)sender;

- (OSPChatStorageObject*)selectedChat;
- (BOOL)isActiveChat:(OSPChatStorageObject*)chat;

    
@end
