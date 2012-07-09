#import "OSPRosterTableCellView.h"

@implementation OSPRosterTableCellView
@synthesize statusTextfield;

// Color and style for custom statusTextfield
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    
    if (backgroundStyle == NSBackgroundStyleDark) {
        self.statusTextfield.textColor = [NSColor windowBackgroundColor];
        
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowBlurRadius:2.0];
        [shadow setShadowOffset:NSMakeSize(2.0, 2.0)];
        self.statusTextfield.shadow = shadow;
        
        
        
        self.textField.textColor = [NSColor windowBackgroundColor];

    } else {
        self.statusTextfield.textColor = [NSColor controlShadowColor];
        self.textField.textColor = [NSColor controlShadowColor];
        
        
    }
    
    [super setBackgroundStyle:backgroundStyle];
}

@end
