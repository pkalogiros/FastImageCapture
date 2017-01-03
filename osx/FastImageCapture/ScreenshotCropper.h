#import <Cocoa/Cocoa.h>

@interface ScreenshotCropper : NSWindowController

- (void)drawImg:(CGImageRef)imgref onSuccess:(void(^)(CGImageRef imgref))success;

- (void)_mouseDown:(NSEvent *)event;
- (void)_mouseUp:(NSEvent *)event;
- (void)_mouseDragged:(NSEvent *)event;
- (void)_keyDown:(NSEvent *)event;

@end
