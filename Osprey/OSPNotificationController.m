#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"

#define RECEIVED_CHAT_MESSAGE_NOTIFICATION_NAME @"incommingChatMessage"
#define RECEIVED_CHAT_MESSAGE_HUMAN_READABLE @"Incomming chat message"

#define RECEIVED_ATTENTION_REQUEST_NOTIFICATION_NAME @"incommingAttentionRequest"
#define RECEIVED_ATTENTION_REQUEST_HUMAN_READABLE @"Incomming attention request"


@implementation OSPNotificationController

# pragma mark - Init
- (id) init {
    self = [super init];
    if (self) {
        // Insert code here to initialize your application 
        
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [[mainBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl"];
        if(NSAppKitVersionNumber >= 1038)
            path = [path stringByAppendingPathComponent:@"1.3"];
        else
            path = [path stringByAppendingPathComponent:@"1.2.3"];
        
        path = [path stringByAppendingPathComponent:@"Growl.framework"];
        NSBundle *growlFramework = [NSBundle bundleWithPath:path];
        if([growlFramework load])
        {
            //NSDictionary *infoDictionary = [growlFramework infoDictionary];
            
            Class GAB = NSClassFromString(@"GrowlApplicationBridge");
            if([GAB respondsToSelector:@selector(setGrowlDelegate:)])
                [GAB performSelector:@selector(setGrowlDelegate:) withObject:self];
        }    
    }
    return self;
}

#pragma mark - Growl registration
- (NSDictionary *) registrationDictionaryForGrowl {
    LOGFUNCTIONCALL
	NSDictionary *notificationsWithDescriptions = [NSDictionary dictionaryWithObjectsAndKeys:
												   RECEIVED_CHAT_MESSAGE_HUMAN_READABLE, RECEIVED_CHAT_MESSAGE_NOTIFICATION_NAME, 
                                                   RECEIVED_ATTENTION_REQUEST_HUMAN_READABLE, RECEIVED_ATTENTION_REQUEST_NOTIFICATION_NAME,				
												   nil];
	
	NSArray *allNotifications = [notificationsWithDescriptions allKeys];
		
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 APP_NAME, GROWL_APP_NAME,
							 allNotifications, GROWL_NOTIFICATIONS_ALL,
							 allNotifications,	GROWL_NOTIFICATIONS_DEFAULT,
							 notificationsWithDescriptions,	GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
							 nil];	
	return regDict;
}




+ (void)growlNotificationForIncommingMessage:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
    [OSPNotificationController genericGrowlNotification:[user displayName] 
                                            description:[[message elementForName:@"body"] stringValue] 
                                       notificationName:RECEIVED_CHAT_MESSAGE_NOTIFICATION_NAME 
                                               iconData:nil 
                                               priority:0 
                                               isSticky:NO 
                                           clickContext:user.jid.bare];
}

+ (void)growlNotificationForIncommingAttentionRequest:(XMPPMessage*)message fromUser:(OSPUserStorageObject*)user {
    [OSPNotificationController genericGrowlNotification:[user displayName] 
                                            description:@"wants wants your attention!" 
                                       notificationName:RECEIVED_ATTENTION_REQUEST_NOTIFICATION_NAME 
                                               iconData:nil 
                                               priority:0 
                                               isSticky:NO 
                                           clickContext:user.jid.bare];
}


// Provides a generic interface for sending growl messages, but checks if notifications are enabled in the preferences
+ (void) genericGrowlNotification:(NSString *)title
                      description:(NSString *)description
                 notificationName:(NSString *)notifName
                         iconData:(NSData *)iconData
                         priority:(signed int)priority
                         isSticky:(BOOL)isSticky
                     clickContext:(id)clickContext {
    
    DDLogError(@"GROWL SUPPORT IS DEPRECATED AND WILL BE REPLACED BY NOTIFICATION CENTER SUPPORT SOON. UNTIL THEN, THIS METHOD DOES NOTHING");
}

@end
