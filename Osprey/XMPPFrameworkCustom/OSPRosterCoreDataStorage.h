#import "XMPPRosterCoreDataStorage.h"

/* 
 * This uses the OSPRoster.xcdatamodel instead of the XMPPRoster.xcdatamodel shipped with the XMPPFramework.
 * In there the entity XMPPUserCoreDataStorageObject uses the OSPUserCoreDataStorage object class to provide getters/setters for custom addtions
 */

@interface OSPRosterCoreDataStorage : XMPPRosterCoreDataStorage <XMPPRosterStorage> {
    
}
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath forUserWithJid:(XMPPJID*)jid onStream:(XMPPStream*)stream;

@end
