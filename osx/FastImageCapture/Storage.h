#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Storage : NSObject

+ (void) storePicture:(NSString *)str withKey:(NSString *)key;
+ (NSArray *) readPicturesFromCache;
+ (NSArray *) deletePictureWithIndex: (unsigned int) index;

@end
