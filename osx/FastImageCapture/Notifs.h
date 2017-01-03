#import <Foundation/Foundation.h>

@interface Notifs : NSObject

+ (void)showDeleteNotification;
+ (void)showSuccessNotification:(NSString *)str withKey:(NSString *)key andImage:(NSImage *)img;
+ (void)showErrorNotification;
+ (void)showDownloadNotification:(NSString *)path andImage:(NSImage *)img;

@end
