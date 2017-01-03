#import "UI.h"
#import "Constants.h"
#import "ScreenshotCropper.h"
#import "ScreenshotListWindow.h"
#import "NetWorking.h"
#import "Storage.h"

// Class BorderlessWindow -- Simple class to accept keyboard events even when marked as NSBorderlessWindowMask
@interface BorderlessWindow:NSWindow{}@end
@implementation BorderlessWindow
- (BOOL)canBecomeKeyWindow { return (YES);}
- (BOOL)canBecomeMainWindow{ return (YES);}
@end
// endof BorderlessWindow

@implementation UI
{
    NSStatusItem *statusItem_;
    ScreenshotCropper *cropwindow_;
    ScreenshotListWindow *listwindow_;
}

+ (UI *)get
{
    static UI *q = nil;

    if (!q) q = [[self alloc] init];
    return (q);
}

- (NSStatusItem *)makeStatusBarIcon
{
    statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem_.title = @"";

    NSString *icon_name = @"fastimagecapture-logo";
    statusItem_.image = [NSImage imageNamed:icon_name];
    statusItem_.alternateImage = [NSImage imageNamed:icon_name];

    statusItem_.highlightMode = YES;

    [statusItem_.button setTarget: self];

    [statusItem_.button sendActionOn: (NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp)];
    
    return (statusItem_);
}


#pragma mark - Helpers

- (ScreenshotListWindow *)listWindowInit:(NSScreen *)screen
{
    if (!listwindow_)
    {
        CGSize screen_size = screen.frame.size;
        CGRect rect = CGRectMake (0.0f, 0.0f, screen_size.width, screen_size.height);
        BorderlessWindow *window = [[BorderlessWindow alloc] initWithContentRect: rect
                                                                       styleMask: NSBorderlessWindowMask
                                                                         backing: NSBackingStoreBuffered
                                                                           defer: NO];
        window.backgroundColor = [NSColor colorWithWhite:1.0f alpha:0.0f];

        listwindow_ = [[ScreenshotListWindow alloc] initWithWindow:window];
    }
    else if (!listwindow_.Visible)
        [listwindow_.window setFrame:screen.frame display:YES];

    if (!listwindow_.Visible)
        [listwindow_ showWindow:[NSApp delegate]];

    return (listwindow_);
}

- (ScreenshotCropper *) cropWindowInit:(NSScreen *)screen
{
    if (!cropwindow_)
    {
        BorderlessWindow *window = [[BorderlessWindow alloc] initWithContentRect:screen.frame
                                                                       styleMask:NSBorderlessWindowMask
                                                                         backing:NSBackingStoreBuffered
                                                                           defer:NO];
        cropwindow_ = [[ScreenshotCropper alloc] initWithWindow:window];
    }
    else
        [cropwindow_.window setFrame:screen.frame display:YES];
    
    [cropwindow_ showWindow:[NSApp delegate]];

    return (cropwindow_);
}

@end
