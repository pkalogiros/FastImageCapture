#import <Foundation/Foundation.h>

@interface NetWorking : NSObject

+ (NSURLSessionTask *)uploadToServer:(NSData *)data  onSuccess:(void(^)(NSString *str, NSString *key))success onError:(void(^)(NSError *err))error;
+ (NSURLSessionTask *)deleteImage:(NSString *)key onSuccess:(void(^)())success onError:(void(^)(NSError *err))error;
+ (Boolean) openURL:(NSString *)urlstr;
+ (void) downloadImage:(NSString *)str withTitle:(NSString *)title onSuccess:(void(^)(NSString *))success;
+ (void) openInFinder:(NSString *)path;
+ (void) copyImageUrl:(NSString *)url;

@end
