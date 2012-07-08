#import "OSPTableView.h"

@implementation OSPTableView

- (BOOL)acceptsFirstResponder 
{
    return NO;
}

- (BOOL)hasOneSelectedRow {
    return (![self allowsMultipleSelection]) && ([self numberOfSelectedRows] > 0);
}

//static CGImageRef createNoiseImageRef(NSUInteger width, NSUInteger height, CGFloat factor)
//{
//    NSUInteger size = width*height;
//    char *rgba = (char *)malloc(size); srand(124);
//    for(NSUInteger i=0; i < size; ++i){rgba[i] = rand()%256*factor;}
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGContextRef bitmapContext = 
//    CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGImageAlphaNone);
//    CFRelease(colorSpace);
//    free(rgba);
//    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
//    CFRelease(bitmapContext);
//    return image;
//}
//
//
//- (void)drawRect:(NSRect)dirtyRect
//{
//    [super drawRect:dirtyRect];
//        static CGImageRef noisePattern = nil;
//        if (noisePattern == nil) noisePattern = createNoiseImageRef(self.bounds.size.width, self.bounds.size.height, 0.03);
//        [NSGraphicsContext saveGraphicsState];
//        [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
//        CGRect noisePatternRect = CGRectZero;
//        noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern), CGImageGetHeight(noisePattern));        
//        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//        CGContextDrawTiledImage(context, noisePatternRect, noisePattern);
//        [NSGraphicsContext restoreGraphicsState];
//    
//}

@end
