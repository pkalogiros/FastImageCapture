#import "ImgCache.h"
#import <Cocoa/Cocoa.h>

@implementation ImgCache

+ (NSString *)getPath
{
    static NSString *path;

    if (!path)
    {
        // an alternative to the NSTemporaryDirectory
        NSString *local_path = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                             NSCachesDirectory, NSUserDomainMask, YES);
        if ([paths count])
        {
            NSString *bundleName =
            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
            local_path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
        }

        path = local_path;
    }

    return (path);
}

+ (void)deleteFileWithURL: (NSString *)url
{
    NSString *full_path = [[ImgCache getPath] stringByAppendingPathComponent: [url lastPathComponent]];
    [[NSFileManager defaultManager] removeItemAtPath: full_path error: nil];
}

+ (void)storeFileWithName: (NSString *)url andData:(NSData *)data
{
    NSString *full_path = [[ImgCache getPath] stringByAppendingPathComponent: [url lastPathComponent]];
    [data writeToFile: full_path atomically: YES];
}

+ (NSImage *) getImage:(NSString *)url
{
    NSString *full_path = [[ImgCache getPath] stringByAppendingPathComponent: [url lastPathComponent]];
    NSImage *img = [[NSImage alloc] initWithContentsOfFile: full_path];

    return (img);
}

@end
