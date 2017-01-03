#import "CaptureHandler.h"
#import "Constants.h"
#import "Storage.h"
#import "NetWorking.h"
#import "ScreenshotCropper.h"
#import "ScreenshotListWindow.h"
#import "UI.h"
#import "Notifs.h"

@implementation CaptureHandler
{
    __weak ScreenshotCropper *cropwindow_;
    __weak ScreenshotListWindow *listwindow_;
    id key_monitor_;
}

+ (CaptureHandler *)get
{
    static CaptureHandler *q = nil;
    
    if (!q) q = [[self alloc] init];
    return (q);
}

- (void)setUpLocalKey
{
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        int k = [event keyCode];
        if (k == 51 || k == 53)
        {
            if (listwindow_ && listwindow_.Visible)
            {
                [listwindow_ close];
                return (event);
            }
            else if (cropwindow_)
            {
                [cropwindow_ close];
            }
            
            [NSEvent removeMonitor: key_monitor_];
            key_monitor_ = nil;
            
            [[NSCursor arrowCursor] set];
        }
        
        return (event);
    }];
}

- (void)initCapture
{
    NSPoint mouse_loc = [NSEvent mouseLocation]; //get current mouse position
    NSScreen *screen = [NSScreen mainScreen];

    for (NSScreen *scr in [NSScreen screens])
    {
        CGRect frame = scr.frame;
        if (   (mouse_loc.x - frame.origin.x) <= frame.size.width
            && (mouse_loc.y - frame.origin.y) <= frame.size.height)
        {
            screen = scr;
            break;
        }
    }

    NSDictionary* screenDictionary = [screen deviceDescription];
    NSNumber* screenID = [screenDictionary objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID aID = [screenID unsignedIntValue];
    CGSize screen_size = screen.frame.size;

    [self setUpLocalKey];

    NSEvent *event = [NSApp currentEvent];

    // if right click, then show the window list
    if (event.type == NSEventTypeRightMouseUp)
    {
        if (listwindow_ && listwindow_.Visible)
        {
            [listwindow_ close];
            return ;
        }

        listwindow_ = [[UI get] listWindowInit:screen];
        return ;
    }

    CGRect rect = CGRectMake (0.0f, 0.0f, screen_size.width, screen_size.height);
    CGImageRef img = CGDisplayCreateImageForRect (aID, rect);

    cropwindow_ = [[UI get] cropWindowInit: screen];
    [cropwindow_ drawImg:img onSuccess:^(CGImageRef imgref) {
        if (!imgref)
        {
            [cropwindow_ close];
            return ;
        }

        float quality  = JPEG_QUALITY;
        int   max_size = JPEG_SIZE_MAX;
        
        NSData *jpeg_img = jpegDataWithCGImage (imgref, quality);

        // if jpeg image is too big, try again with supplying a lower quality
        while (jpeg_img.length > max_size && quality > 0.32f)
        {
            quality -= 0.10f;
            jpeg_img = jpegDataWithCGImage (imgref, quality);
            NSLog (@"JPEG IMG size is %lu", (unsigned long)jpeg_img.length);
        }
        
        NSImage *placeholder_img = [[NSImage alloc] initWithCGImage: imgref size: CGSizeMake (220.0f, 220.0f)];
        CFRelease (imgref); // clean up memory

        [NetWorking uploadToServer: jpeg_img onSuccess:^(NSString *str, NSString *key) {
            [Notifs showSuccessNotification: str withKey: key andImage:placeholder_img];
        } onError:^(NSError *err) {
            [Notifs showErrorNotification];
        }];
        
        [cropwindow_ close];
        return ;
    }];
    
    [NSApp activateIgnoringOtherApps: YES];
    
    return ;
}


#pragma mark - Helpers

static inline NSData *jpegDataWithCGImage (CGImageRef cgImage, CGFloat compressionQuality)
{
    NSData *jpegData = nil;
    
    CFMutableDataRef      data = CFDataCreateMutable (NULL, 0);
    CGImageDestinationRef idst = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, NULL);
    if (idst)
    {
        NSInteger exif = 1;
        NSDictionary *props = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality], kCGImageDestinationLossyCompressionQuality, [NSNumber numberWithInteger:exif], kCGImagePropertyOrientation, nil];
        
        CGImageDestinationAddImage(idst, cgImage, (CFDictionaryRef)props);
        if (CGImageDestinationFinalize(idst))
            jpegData = [NSData dataWithData: (__bridge NSData *)data];
        
        CFRelease (idst);
    }
    CFRelease (data);
    
    return (jpegData);
}


@end
