#import <Cocoa/Cocoa.h>

@interface OSPPreferencesController : NSObject <NSToolbarDelegate, NSWindowDelegate> 
{	
	IBOutlet NSView *view1;
	IBOutlet NSView *view2;
	IBOutlet NSView *view3;
	IBOutlet NSView *contentView;
	IBOutlet NSWindow *window;
    IBOutlet NSPopUpButton *logPathButton;
    IBOutlet NSMenuItem *logPathMenuItem;
    IBOutlet NSTextField *passwordTextField;
    IBOutlet NSTextField *jidTextField;
}

-(void)mapViewsToToolbar;
-(void)firstPane;
-(IBAction)changePanes:(id)sender;
-(IBAction)choseLogPath:(id)sender;
-(IBAction)changeJid:(id)sender;
-(void)setPasswordForJid:(NSString*)jid;
-(IBAction)changePassword:(id)sender;

@end
