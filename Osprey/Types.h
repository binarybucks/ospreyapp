#ifndef Osprey_Types_h
#define Osprey_Types_h

#import <CoreData/CoreData.h>
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRosterCoreDataStorage.h"
#import "OSPRosterCoreDataStorage.h"

typedef OSPRosterCoreDataStorage OSPRosterStorage;
typedef XMPPUserCoreDataStorageObject OSPUserStorageObject;

@class OSPChatCoreDataStorageObject;
typedef OSPChatCoreDataStorageObject OSPChatStorageObject;

typedef enum {
    noError,
    connectionError,
    authenticationError,
    registrationError,
}
EErrorState;

typedef enum {
    disconnected = 0,
    connecting = 1,
    connected = 2,
    authenticating = 4,
    authenticated = 8,
    registering = 16,
    registered = 32,
}
EConnectionState;

typedef enum {
    dnd = 0,
    xa = 1,
    away = 2,
    online = 3,
    chat = 4,
}
EStatusState;

typedef enum {
    singleChat = 1,
    multiChat = 2,
}
EChatType;

#endif /* ifndef Osprey_Types_h */
