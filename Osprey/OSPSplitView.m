#import "OSPSplitView.h"

@implementation OSPSplitView

- (NSColor *)dividerColor {
   return ([NSApp isActive] && [[self window] isMainWindow]) ? [NSColor darkGrayColor] : [NSColor lightGrayColor];
}

@end
