#import "AppDelegate.h"
#import "ScreenshotCropper.h"
#import "Constants.h"
#import "NetWorking.h"
#import "UI.h"
#import "CaptureHandler.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // make sure our app is minized
    [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    [self.window miniaturize:nil];

    // and also that is has a corresponding menu bar icon
    NSStatusItem *status_icon = [[UI get] makeStatusBarIcon];
    [status_icon setTarget:[CaptureHandler get]];
    [status_icon.button setAction: @selector (initCapture)];

    // set the local notifications delegate so that we know when a picture has been uploaded
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}


#pragma mark - NSNotificationsDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return (YES);
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if (!notification.userInfo) return ;

    if ([notification.userInfo objectForKey:@"k"])
    {
        NSString *str = [notification.userInfo objectForKey:@"k"];
        [NetWorking openURL: str];
    }
    else if ([notification.userInfo objectForKey:@"j"])
    {
        NSString *str = [notification.userInfo objectForKey:@"j"];
        [NetWorking openInFinder: str];
    }
}


@end
