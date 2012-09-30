#import <Cocoa/Cocoa.h>

@interface OSPPreferencesController : NSObject <NSToolbarDelegate, NSWindowDelegate, NSTextFieldDelegate>
{
    IBOutlet NSView *view1;
    IBOutlet NSView *view2;
    IBOutlet NSView *view3;
    IBOutlet NSView *contentView;
    IBOutlet NSTextField *passwordTextField;
    IBOutlet NSTextField *jidTextField;
    IBOutlet NSTextField *serverTextField;
}
@property (weak) IBOutlet NSWindow *window;

- (void) mapViewsToToolbar;
- (void) firstPane;
- (IBAction) changePanes:(id)sender;
- (void) changePanesProgramatically:(NSInteger)pane;

- (IBAction) changeJid:(id)sender;
- (IBAction) changePassword:(id)sender;
- (void) setPasswordForJid:(NSString *)jid;

- (IBAction) resetStores:(id)sender;
- (IBAction) resetPreferences:(id)sender;

@end
