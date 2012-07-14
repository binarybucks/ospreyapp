#import <Cocoa/Cocoa.h>

@interface OSPPreferencesController : NSObject <NSToolbarDelegate, NSWindowDelegate, NSTextFieldDelegate> 
{	
	IBOutlet NSView *view1;
	IBOutlet NSView *view2;
	IBOutlet NSView *view3;
	IBOutlet NSView *contentView;
	IBOutlet NSWindow *window;
    IBOutlet NSTextField *passwordTextField;
    IBOutlet NSTextField *jidTextField;
    IBOutlet NSTextField *serverTextField;
}

-(void)mapViewsToToolbar;
-(void)firstPane;
-(IBAction)changePanes:(id)sender;
-(IBAction)changeJid:(id)sender;
-(IBAction)changePassword:(id)sender;
-(void)setPasswordForJid:(NSString*)jid;
@end
