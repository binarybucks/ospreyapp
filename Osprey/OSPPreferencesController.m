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
	[window center];
}

#pragma mark - Map
-(void)mapViewsToToolbar {
	NSString *app = @"Preferences"; // Window title
	
    NSToolbar *toolbar = [window toolbar];
	if(toolbar == nil)  
	{
		toolbar = [[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.mgpreferencepanel.toolbar", app]];
	}
	
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
	[toolbar setDelegate: self]; 
	
	[window setToolbar: toolbar];	
	[window setTitle:View1ItemIdentifier];
	
	if([toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)])
	{
		[toolbar setSelectedItemIdentifier: View1ItemIdentifier];
	}	
}

-(IBAction)changePanes:(id)sender {
	NSView *view = nil;
	
	switch ([(NSView*)sender tag]) 
	{
		case 0:
			[window setTitle:View1ItemIdentifier];
			view = view1;
			break;
		case 1:
			[window setTitle:View2ItemIdentifier];
			view = view2;
			break;
		case 2:
			[window setTitle:View3ItemIdentifier];
			view = view3;
			break;
		default:
			break;
	}
	NSRect windowFrame = [window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	[window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}

#pragma mark - First pane
-(void)firstPane {
	NSView *view = nil;
	view = view1;
	
	NSRect windowFrame = [window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	[window setFrame:windowFrame display:YES animate:YES];
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

# pragma mark - Log path selection
-(IBAction)choseLogPath:(id)sender {
    LOGFUNCTIONCALL
    NSOpenPanel *tvarNSOpenPanelObj = [NSOpenPanel openPanel]; 
    [tvarNSOpenPanelObj setAllowsMultipleSelection:NO];
    [tvarNSOpenPanelObj setCanChooseFiles:NO];
    [tvarNSOpenPanelObj setCanChooseDirectories:YES];
    
    [tvarNSOpenPanelObj setCanCreateDirectories:YES];

    NSInteger tvarNSInteger = [tvarNSOpenPanelObj runModal]; 
    
    if(tvarNSInteger == NSOKButton)
    { 
        NSLog(@"doOpen we have an OK button"); 
    } else if(tvarNSInteger == NSCancelButton) { 
        NSLog(@"doOpen we have a Cancel button"); 
        return; 
    } else { 
        NSLog(@"doOpen tvarInt not equal 1 or zero = %3ld",tvarNSInteger);
        return; 
    } // end if NSString * tvarDirectory = [tvarNSOpenPanelObj directory]; NSLog(@"doOpen directory = %@",tvarDirectory); NSString * tvarFilename = [tvarNSOpenPanelObj filename]; NSLog(@"doOpen filename = %@",tvarFilename);
    NSURL * tvarDirectory = [tvarNSOpenPanelObj directoryURL]; 
    [[NSUserDefaults standardUserDefaults] setURL:tvarDirectory forKey:@"LogPath"];
    
    [logPathButton selectItem:logPathMenuItem];
}
    
-(IBAction)changeJid:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserChangedJid"
                                                        object:self];
    [self setPasswordForJid:[sender stringValue]];
}


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



@end
