#import <Foundation/Foundation.h>

@interface ImgCache : NSObject

+ (NSString *) getPath;
+ (NSImage *) getImage:(NSString *)url;
+ (void) deleteFileWithURL: (NSString *)url;
+ (void) storeFileWithName: (NSString *)url andData:(NSData *)data;

@end
