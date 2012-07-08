#import "OSPRosterTableCellView.h"

@implementation OSPRosterTableCellView
@synthesize statusTextfield;

// Color and style for custom statusTextfield
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    LOGFUNCTIONCALL
    NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor windowBackgroundColor] : [NSColor controlShadowColor];
    self.statusTextfield.textColor = textColor;
    [super setBackgroundStyle:backgroundStyle];
}

@end
