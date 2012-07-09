#import "OSPNotificationController.h"
#import "NSXMLElement+XMPP.h"
@implementation OSPNotificationController {
    
}

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
        NSLog(@"path: %@", path);
        NSBundle *growlFramework = [NSBundle bundleWithPath:path];
        if([growlFramework load])
        {
            NSDictionary *infoDictionary = [growlFramework infoDictionary];
            NSLog(@"Using Growl.framework %@ (%@)",
                  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
                  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
            
            Class GAB = NSClassFromString(@"GrowlApplicationBridge");
            if([GAB respondsToSelector:@selector(setGrowlDelegate:)])
                [GAB performSelector:@selector(setGrowlDelegate:) withObject:self];
        }    }
    return self;
}

- (NSDictionary *) registrationDictionaryForGrowl {
    LOGFUNCTIONCALL
	NSDictionary *notificationsWithDescriptions = [NSDictionary dictionaryWithObjectsAndKeys:
												   @"Received chat message", @"receivedChatMessage",				
												   nil];
	
	NSArray *allNotifications = [notificationsWithDescriptions allKeys];
		
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"MultiGrowlExample", GROWL_APP_NAME,
							 allNotifications, GROWL_NOTIFICATIONS_ALL,
							 allNotifications,	GROWL_NOTIFICATIONS_DEFAULT,
							 notificationsWithDescriptions,	GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
							 nil];	
	return regDict;
}




+ (void)growlNotificationFromMessage:(XMPPMessage*)message boundToUser:(OSPUserStorageObject*)userForCallback;
{
    [OSPNotificationController growlNotificationFromString:[[message elementForName:@"body"] stringValue] withTitle:userForCallback.displayName boundToUserBareJid:userForCallback.jid.bare];
}

+ (void)growlNotificationFromString:(NSString*)string withTitle:(NSString*)title boundToUserBareJid:(NSString*)userJidForCallback {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:STDUSRDEF_GENERALDISPLAYGROWLNOTIFICATIONS]) {
        return;
    }

    Class GAB = NSClassFromString(@"GrowlApplicationBridge");
    NSLog(@"gab %@", GAB);
	if([GAB respondsToSelector:@selector(notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:identifier:)]) {
        NSLog(@"asdf");
        
		[GAB notifyWithTitle:title
                 description:string
            notificationName:@"notification"
                    iconData:nil
                    priority:0
                    isSticky:NO
                clickContext:userJidForCallback
                  identifier:nil];
    }

}



- (void) growlNotificationWasClicked:(id)clickContext {
    [[[NSApp delegate] chatController] openChatWithJid:[XMPPJID jidWithString:clickContext]];
}






@end
