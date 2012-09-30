#import "XMPPCoreDataStorage.h"
#import "OSPChatCoreDataStorageObject.h"

@interface OSPChatCoreDataStorage : XMPPCoreDataStorage
- (XMPPJID *) myJIDForXMPPStream:(XMPPStream *)stream;

@end
