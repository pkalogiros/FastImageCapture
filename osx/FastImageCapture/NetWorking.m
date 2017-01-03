#import "NetWorking.h"
#import "Constants.h"

@implementation NetWorking

+ (NSURLSessionTask *)uploadToServer:(NSData *)data  onSuccess:(void(^)(NSString *str, NSString *key))success onError:(void(^)(NSError *err))error
{
    NSString *url = [SERVER_DOMAIN stringByAppendingString:@"projects/fastimagecapture/upload.php?k=g8ya0g84SFHSRngaduaEshdhufHfsirkLprghsrFUKariola"];
    url = [url stringByAppendingString:[NetWorking makeSignature]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];

    [request setHTTPBody:data];
    [request setHTTPMethod:@"PUT"];

    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                                      NSURLResponse *response,
                                                                                      NSError *err)
                              {
                                  if (err)
                                  {
                                      if (error) error (err);
                                      return ;
                                  }
                                  
                                  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                  if (dic && [[dic objectForKey:@"success"] intValue] == 1)
                                  {
                                      if (success) success ([dic objectForKey:@"u"],
                                                            [dic objectForKey:@"k"]);
                                      return ;
                                  }
                                  
                                  if (error) error (nil);
                              }];
    
    [task resume];
    return (task);
}

+ (NSURLSessionTask *)deleteImage:(NSString *)key onSuccess:(void(^)())success onError:(void(^)(NSError *err))error
{
    NSString *url = [SERVER_DOMAIN stringByAppendingString:@"projects/fastimagecapture/delete.php?k=g8ya0g84SFHSRngaduaEshdhufHfsirkLprghsrFUKariola&d="];
    url = [url stringByAppendingString:[NetWorking urlEncode:key]];
    url = [url stringByAppendingString:[NetWorking makeSignature]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:5.0f];

    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                                      NSURLResponse *response,
                                                                                      NSError *err)
                              {
                                  if (err)
                                  {
                                      if (error) error (err);
                                      return ;
                                  }
                                  
                                  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                  if (dic && [[dic objectForKey:@"success"] intValue] == 1)
                                  {
                                      if (success) success ();
                                      return ;
                                  }

                                  if (error) error (err);
                              }];
    
    [task resume];
    return (task);
}

+ (NSString *)makeSignature
{
    // secret signature logic here
    // ####
    return (@"");
}

+ (NSString *)urlEncode:(NSString *)enc
{
    return ([enc stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]);
}

+ (Boolean) openURL: (NSString *)urlstr
{
    // validate URL (that indeed we are trying to open a .jpg image)
    NSURL *url = [NSURL URLWithString:urlstr];
    if (url && [urlstr hasPrefix:SERVER_DOMAIN] && [urlstr hasSuffix:@".jpg"])
    {
        // ask the system to open the default browser
        system ([[NSString stringWithFormat:@"open %@", urlstr] UTF8String]);
        
        return (YES);
    }

    return (NO);
}

+ (void) openInFinder: (NSString *)path
{
    if (path && [path hasSuffix:@".jpg"] && path.length > 8)
        system ([[NSString stringWithFormat:@"open -R \"%@\"", path] UTF8String]);
}

+ (void) downloadImage:(NSString *)str withTitle:(NSString *)title onSuccess:(void(^)(NSString *))success
{
    NSURL  *url = [NSURL URLWithString: str];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        if (urlData && urlData.length > 100)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, title];
            [urlData writeToFile:filePath atomically: YES];
            
            if (success) success (filePath);
        }
    });
}

+ (void) copyImageUrl:(NSString *)url
{
    system ([[NSString stringWithFormat:@"echo '%@' | pbcopy", url] UTF8String]);
}

@end
