#import "Notifs.h"
#import "Storage.h"

@implementation Notifs

+ (void)showSuccessNotification:(NSString *)str withKey:(NSString *)key andImage:(NSImage *)img
{
    dispatch_async (dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:str forKey:@"k"];

        notification.title = @"ImageCapture Success";
        notification.informativeText = [NSString stringWithFormat:@"Uploaded at %@", str];
        notification.userInfo = info;
        
        if (img) notification.contentImage = img;
        
        [Storage storePicture: str withKey: key];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

+ (void)showErrorNotification
{
    dispatch_async (dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"ImageCapture Failure";
        notification.informativeText = @"Oh no, your internet connection is down or pantel.is is down, again";

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

+ (void)showDeleteNotification
{
    dispatch_async (dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Image Deleted";
        notification.informativeText = @"";

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

+ (void)showDownloadNotification:(NSString *)path andImage:(NSImage *)img
{
    dispatch_async (dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Image Downloaded";
        notification.informativeText = @"Click/tap here to open in finder";

        if (img) notification.contentImage = img;

        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject: path forKey:@"j"];
        notification.userInfo = info;
 
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

@end
