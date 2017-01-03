#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class ScreenshotCropper;
@class ScreenshotListWindow;
@interface UI : NSObject

- (NSStatusItem *) makeStatusBarIcon;
- (ScreenshotListWindow *)listWindowInit:(NSScreen *)screen;
- (ScreenshotCropper *) cropWindowInit:(NSScreen *)screen;

+ (UI *) get;


@end
