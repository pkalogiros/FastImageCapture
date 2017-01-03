#import "Storage.h"

@implementation Storage

static NSString *list = @"list";

+ (void) storePicture:(NSString *)str withKey:(NSString *)key
{
    @synchronized ([NSApp delegate])
    {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        NSMutableArray *arr = [NSMutableArray arrayWithArray:[prefs objectForKey: list]];
        if (!arr) arr = [NSMutableArray array];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE MMM dd HH:mm  (yyyy)"];
        
        NSDate *date = [NSDate date];
        NSString *datestr  = [dateFormatter stringFromDate: date];
        NSNumber *timestamp = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
        
        [arr insertObject:@[str, key, datestr, timestamp] atIndex:0];
        
        [prefs setObject:arr forKey: list];
        [prefs synchronize];
    }
}

+ (NSArray *) readPicturesFromCache
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return ([prefs objectForKey: list]);
}

+ (NSArray *) deletePictureWithIndex: (unsigned int) index
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[prefs objectForKey: list]];

    if (!arr) return (nil);

    [arr removeObjectAtIndex: index];
    
    [prefs setObject: arr forKey: list];
    [prefs synchronize];
    
    return (arr);
}

@end
