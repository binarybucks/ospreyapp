#import "OSPTitleBarView.h"

@implementation OSPTitleBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) awakeFromNib {
    [[title cell] setBackgroundStyle:NSBackgroundStyleRaised];

}
- (void)drawRect:(NSRect)dirtyRect
{
    if([NSApp isActive] && [[self window] isMainWindow]) {
        [title setEnabled:YES];
    } else {
        [title setEnabled:NO];
    }
}

@end
