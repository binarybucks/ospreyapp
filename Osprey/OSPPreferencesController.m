#import "OSPPreferencesController.h"
#import "INKeychainAccess.h"
#define WINDOW_TOOLBAR_HEIGHT 78

NSString * const View1ItemIdentifier =  @"General";
NSString * const View1IconImageName =   @"General";
NSString * const View2ItemIdentifier =  @"Account";
NSString * const View2IconImageName =   @"Account";
NSString * const View3ItemIdentifier =  @"Developer";
NSString * const View3IconImageName =   @"Developer";

@implementation OSPPreferencesController   

#pragma mark - Init
-(void)awakeFromNib {
    LOGFUNCTIONCALL
	[self mapViewsToToolbar];
	[self firstPane];
    [self setPasswordForJid:[[NSUserDefaults standardUserDefaults] valueForKey:STDUSRDEF_ACCOUNTJID]];
	[self.window center];
}

#pragma mark - Map
-(void)mapViewsToToolbar {
	NSString *app = @"Preferences"; // Window title
	
    NSToolbar *toolbar = [self.window toolbar];
	if(toolbar == nil)  
	{
		toolbar = [[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.mgpreferencepanel.toolbar", app]];
	}
	
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
	[toolbar setDelegate: self]; 
	
	[self.window setToolbar: toolbar];
	[self.window setTitle:View1ItemIdentifier];
	
	if([toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)])
	{
		[toolbar setSelectedItemIdentifier: View1ItemIdentifier];
	}	
}


-(IBAction)changePanes:(id)sender {
	[self changePanesProgramatically:[(NSView*)sender tag]];
}

- (void)changePanesProgramatically:(NSInteger)pane {
    NSView *view = nil;
    switch (pane)   {
    case 0:
        [self.window setTitle:View1ItemIdentifier];
        view = view1;
        break;
    case 1:
        [self.window setTitle:View2ItemIdentifier];
        view = view2;
        break;
    case 2:
        [self.window setTitle:View3ItemIdentifier];
        view = view3;
        break;
    default:
        break;
	}
	NSRect windowFrame = [self.window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([self.window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	[self.window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];

}

#pragma mark - First pane
-(void)firstPane {
	NSView *view = nil;
	view = view1;
	
	NSRect windowFrame = [self.window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([self.window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	[self.window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}

#pragma mark - Default, alowed, selectable
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
			View1ItemIdentifier,
			View2ItemIdentifier,
			View3ItemIdentifier,
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
			View1ItemIdentifier,
			View2ItemIdentifier,
			View3ItemIdentifier,
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			nil];
}

- (NSArray*)toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:
			View1ItemIdentifier,
			View2ItemIdentifier,
			View3ItemIdentifier,
			nil];
}

#pragma mark - Item for identifier
- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSToolbarItem *item = nil;
	
    if ([itemIdentifier isEqualToString:View1ItemIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:itemIdentifier];
        [item setLabel:itemIdentifier];
        [item setImage:[NSImage imageNamed:View1IconImageName]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:0];
    }
	else if ([itemIdentifier isEqualToString:View2ItemIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:itemIdentifier];
        [item setLabel:itemIdentifier];
        [item setImage:[NSImage imageNamed:View2IconImageName]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:1];
    }
	else if ([itemIdentifier isEqualToString:View3ItemIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:itemIdentifier];
        [item setLabel:itemIdentifier];
        [item setImage:[NSImage imageNamed:View3IconImageName]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:2];
    }
	return item;
}

// If the user changes the jid in the preferences we send a UserChangedJid notification to filter the roster by the new jid
// Additionally, we look up the password for the new jid, so the user does not have to enter it again
-(IBAction)changeJid:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserChangedJid"
                                                        object:self];
    [self setPasswordForJid:[sender stringValue]];
}


// If the user changes password, we store it savely in the keychain. 
// If no entry exists, we have to create it first
-(IBAction)changePassword:(id)sender {    
    NSString *jid = [jidTextField stringValue];
    NSString *pw =  [passwordTextField stringValue];
    NSError *kcErr = nil;
    NSError *setErr = nil;
    
    SecKeychainItemRef keyChainItem = nil;
    
    if (([jid length] == 0) || ([pw length] == 0)) 
        return; 
    
    keyChainItem = [INKeychainAccess itemRefForAccount:jid serviceName:APP_NAME error:&kcErr];
    
    if (keyChainItem == nil) {
        [INKeychainAccess addKeychainItemForAccount:jid withPassword:pw serviceName:APP_NAME error:&setErr];
    } else {
        [INKeychainAccess setPassword:[sender stringValue] forAccount:[jidTextField stringValue] serviceName:APP_NAME error:&setErr];
    }
    
    if (setErr) {
        DDLogError(@"Error setting password :%@", setErr);
    }
}

// This is triggered whenever the value of the jid textfield changes.
// This automatically writes the server part of a jid to the server textfield while the user is entering his jid. 
// There are situations where the part after the @ is not the server, that is impossible to know for us
- (void)controlTextDidChange:(NSNotification *)aNotification {
    
    NSRange range = [jidTextField.stringValue rangeOfString:@"@"];
    
    if (range.location != NSNotFound){
        [serverTextField setStringValue:[jidTextField.stringValue substringFromIndex:range.location+1]];
    }
}

// Looks up the passwort for the specific jid and sets is as value for the password textfield
- (void)setPasswordForJid:(NSString*)jid {
    if ([jid length] == 0)
        return; 
    NSError *err = nil;
    NSString *password = [INKeychainAccess passwordForAccount:jid serviceName:APP_NAME error:&err];
    
    if (([password length] == 0) || (!password)) {
        [passwordTextField setStringValue:@""];
    } else {
        [passwordTextField setStringValue:password];
    }
}


# pragma mark - Resets
- (IBAction)resetStores:(id)sender {
    NSBeep();
    NSBeginAlertSheet(@"Danger Will Robinson!", @"Cancel", @"Delete", nil, self.window, self, @selector(resetStoresAlertSheetDidEnd:returnCode:contextInfo:), nil, nil, @"This operation might be potentially harmfull to your computer. By clicking Delete you acknowledge that you use this function at your own risk and hold only yourself responsible for any data-loss you might encounter.\n\nThis deletes ALL files in ~/Library/Application Support/Osprey.");
}


- (void)resetStoresAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertAlternateReturn) {
        DDLogInfo(@"User agreed to remove all files in ~/Library/Application Support/Osprey is on his own risk. Proceeding");
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask,   YES);
        NSString *appsApplicationSupportFolderPath = [[paths lastObject] stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"]];
        
        NSFileManager* fm = [[NSFileManager alloc] init];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:appsApplicationSupportFolderPath];
        NSError* err = nil;
        BOOL res;
        
        NSString* file;
        while (file = [en nextObject]) {
            DDLogInfo(@"REMOVING : %@", [appsApplicationSupportFolderPath stringByAppendingPathComponent:file]);
            res = [fm removeItemAtPath:[appsApplicationSupportFolderPath stringByAppendingPathComponent:file] error:&err];
            if (!res && err) {
                DDLogError(@"oops: %@", err);
            }
        }
    } else {
        DDLogInfo(@"Reset stores was canceled by the user");
    }
}

- (IBAction)resetPreferences:(id)sender {
    NSBeginAlertSheet(@"Danger Will Robinson!", @"Cancel", @"Delete", nil, self.window, self, @selector(resetPreferencesAlertSheetDidEnd:returnCode:contextInfo:), nil, nil, @"This operation might be potentially harmfull to your computer. By clicking Delete you acknowledge that you use this function at your own risk and hold only yourself responsible for any data-loss you might encounter.\n\nThis deletes the file  ~/Library/Preferences/org.ospreyapp.Osprey.plist.");
    
}
- (void)resetPreferencesAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertAlternateReturn) {

        DDLogInfo(@"User agreed to remove ~/Library/Preferences/org.ospreyapp.Osprey.plist is on his own risk. Proceeding");

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,   YES);
        NSString *appsPreferencesFilePath = [[paths lastObject] stringByAppendingPathComponent:@"Preferences/org.ospreyapp.Osprey.plist"];
        NSFileManager* fm = [[NSFileManager alloc] init];
        NSError* err = nil;
        BOOL res;
        DDLogInfo(@"REMOVING : %@", appsPreferencesFilePath);

        res = [fm removeItemAtPath:appsPreferencesFilePath error:&err];
        if (!res && err) {
            DDLogError(@"oops: %@", err);
        }
    } else {
        DDLogInfo(@"Reset preferences was canceled by the user");
    }
}
@end
