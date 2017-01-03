#import "ScreenshotListWindow.h"
#import "NetWorking.h"
#import "Constants.h"
#import "Storage.h"
#import "Notifs.h"
#import "ImgCache.h"

@interface FirstResponderView : NSView
@end

@implementation FirstResponderView

- (BOOL) acceptsFirstResponder
{
    return (YES);
}
- (BOOL) becomeFirstResponder
{
    return (YES);
}

@end


@interface ScreenshotListWindow ()
{
    NSWindow *window_;

    NSView *bg_overlay_;
    NSView *main_view_;
    NSScrollView *scrollview_;

    NSTextView *nothing_here_;
    NSArray *pic_list_;
    
    Boolean is_deleting_image_;
}

@end

@implementation ScreenshotListWindow

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    window_ = window;
    
    return (self);
}

- (void)showWindow:(id)sender
{
    [window_ makeKeyAndOrderFront: self];
    window_.level = 1000;

    CGRect frame = window_.frame;
    frame.origin.x = 0; frame.origin.y = 0;

    bg_overlay_ = [[FirstResponderView alloc] initWithFrame:frame];
    [bg_overlay_ setWantsLayer:YES];

    [window_.contentView addSubview: bg_overlay_];
    bg_overlay_.layer.backgroundColor = [NSColor colorWithWhite:1.0f alpha:0.02f].CGColor;

    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget: self
                                                                                action: @selector (closeWindow)];
    [bg_overlay_ addGestureRecognizer: click];

    CGRect rect = CGRectMake (frame.size.width - 525, frame.size.height - 525, 500, 500);
    main_view_ = [[NSView alloc] initWithFrame: rect];
    main_view_.layer.backgroundColor = [NSColor colorWithWhite:1.0f alpha:0.4f].CGColor;
    [main_view_ setWantsLayer:YES];

    [window_.contentView addSubview: main_view_];

    main_view_.layer.borderWidth = 1.0f;
    main_view_.layer.borderColor = [NSColor darkGrayColor].CGColor;
    main_view_.layer.backgroundColor = [NSColor colorWithWhite:1.0f alpha:1.0f].CGColor;

    [super showWindow:sender];
    self.Visible = YES;

    rect.origin.x = 0; rect.origin.y = 0;
    scrollview_ = [[NSScrollView alloc] initWithFrame: rect];
    [scrollview_ setScrollerStyle: NSScrollerStyleOverlay];

    NSView *v = [[NSView alloc] initWithFrame: rect];
    [scrollview_ setDocumentView: v];
    
    [main_view_ addSubview: scrollview_];

    [self setUpScrollView];
    [NSApp activateIgnoringOtherApps: YES];

    [bg_overlay_ becomeFirstResponder];
}

- (void) setUpScrollView
{
    NSArray *arr = [Storage readPicturesFromCache];
    if (!arr || arr.count == 0)
    {
        if (!nothing_here_)
        {
            nothing_here_ = [[NSTextView alloc] initWithFrame: CGRectMake (50.0f, 100.0f, 400.f, 400.0f)];
            nothing_here_.editable = NO;
            nothing_here_.string = @"NO PICS UPLOADED YET. START CAPTURING :)";
            nothing_here_.font = [NSFont fontWithName:@"HelveticaNeue-Thin" size:30.0f];
            [scrollview_ addSubview:nothing_here_];
        }

        [nothing_here_ setHidden: NO];
    }
    else
    {
        [nothing_here_ setHidden: YES];

        // create the cells
        [self makeScrollViewCells:arr];
    }
}

- (void) setImageTo:(NSImageView *)view withURL:(NSString *)url
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.Visible) return ;
        

        NSImage *smallImage = [ImgCache getImage: url];
        if (!smallImage)
        {
            @autoreleasepool
            {
                // check in the cache
                
                NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
                if (!image) return ;
                CGSize newSize = CGSizeMake (250, 250 / (image.size.width/image.size.height));
                smallImage = [[NSImage alloc] initWithSize: newSize];
                [smallImage lockFocus];
                [image setSize: newSize];
                [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
                [image drawAtPoint:NSZeroPoint fromRect:CGRectMake (0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
                [smallImage unlockFocus];
                image = nil;

                NSData *imageData = [smallImage TIFFRepresentation];
                NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: imageData];
                NSNumber *compressionFactor = [NSNumber numberWithFloat: 0.5f];
                NSDictionary *imageProps = [NSDictionary dictionaryWithObject: compressionFactor
                                                                       forKey: NSImageCompressionFactor];
                imageData = [imageRep representationUsingType: NSJPEGFileType properties: imageProps];

                [ImgCache storeFileWithName: url andData: imageData];
            }
        }

        
        if (smallImage)
            dispatch_async (dispatch_get_main_queue(), ^{
                if (!self.Visible) return ;
                view.image = smallImage;
            });
    });
}

- (void) createEntryToImageView:(NSImageView *)imageView andImgHolder:(NSView *)imgholder
                       andIndex:(unsigned int)l
                        andDate:(NSString *)date
                   andTimestamp:(NSNumber *)timestamp
{
    [imageView addCursorRect:imageView.bounds cursor:[NSCursor pointingHandCursor]];

    // add DELETE button
    NSButton *delete = [[NSButton alloc] initWithFrame: CGRectMake (imageView.frame.size.width + imageView.frame.origin.x + 18.0f, 70.0f, 100.0f, 20.0f)];
    [delete setTitle:@"DELETE IMAGE"];
    [delete setBordered:NO];
    delete.tag = l;
    [delete setAction: @selector (deleteImage:)];
    [delete addCursorRect:delete.bounds cursor:[NSCursor pointingHandCursor]];
    
    NSButton *download = [[NSButton alloc] initWithFrame: CGRectMake (delete.frame.size.width + delete.frame.origin.x + 18.0f, 70.0f, 120.0f, 20.0f)];
    [download setTitle:@"DOWNLOAD IMAGE"];
    [download setBordered:NO];
    download.tag = l;
    [download setAction: @selector (downloadImage:)];
    [download addCursorRect:delete.bounds cursor:[NSCursor pointingHandCursor]];
    
    NSButton *copy_url = [[NSButton alloc] initWithFrame: CGRectMake (download.frame.size.width + download.frame.origin.x + 18.0f, 70.0f, 78.0f, 20.0f)];
    [copy_url setTitle:@"COPY URL"];
    [copy_url setBordered:NO];
    copy_url.tag = l;
    [copy_url setAction: @selector (copyImageUrl:)];
    [copy_url addCursorRect:delete.bounds cursor:[NSCursor pointingHandCursor]];
    
    NSButton *open_in_new = [[NSButton alloc] initWithFrame: imageView.frame];
    [open_in_new setAction: @selector (openImage:)];
    open_in_new.tag = l;
    open_in_new.alphaValue = 0.0f;
    
    NSTextView *index_view = [[NSTextView alloc] initWithFrame: CGRectMake (imgholder.frame.size.width - 44.0f, 1.0f, 32.0f, 16.0f)];
    index_view.string = [NSString stringWithFormat:@"%d", (l + 1)];
    index_view.alignment = NSTextAlignmentRight;
    index_view.textColor = [NSColor darkGrayColor];
    index_view.font = [NSFont fontWithName:@"HelveticaNeue-Thin" size:9.0f];
    
    NSTextView *date_full = [[NSTextView alloc] initWithFrame: CGRectMake (imageView.frame.size.width + imageView.frame.origin.x + 20.0f, 110.0f, 250.0f, 20.0f)];
    date_full.editable = NO;
    date_full.string = date;
    date_full.font = [NSFont fontWithName:@"HelveticaNeue-Thin" size:16.0f];
    
    // create time ago string
    NSTextView *date_short = [[NSTextView alloc] initWithFrame: CGRectMake (imgholder.frame.size.width - 130, 110.0f, 120.0f, 20.0f)];
    date_short.editable = NO;
    date_short.string = [self dateDiff:timestamp];
    date_short.alignment = NSTextAlignmentRight;
    date_short.textColor = [NSColor darkGrayColor];
    date_short.font = [NSFont fontWithName:@"HelveticaNeue-Thin" size:14.0f];
    
    dispatch_async (dispatch_get_main_queue(), ^{
        [imageView setWantsLayer: YES];
        
        imageView.layer.borderColor = [NSColor darkGrayColor].CGColor;
        imageView.layer.borderWidth = 2.0f;
        [imgholder setWantsLayer: YES];
        
        CALayer *rightBorder = [CALayer layer];
        rightBorder.borderColor = [NSColor colorWithWhite:0.94f alpha:1.0f].CGColor;
        rightBorder.borderWidth = 1;
        rightBorder.frame = CGRectMake (0.0f, 0.0f, CGRectGetWidth (imgholder.frame), CGRectGetHeight (imgholder.frame) + 2);
        
        [imgholder.layer addSublayer:rightBorder];
        
        [imgholder addSubview:date_full];
        [imgholder addSubview: imageView];
        [imgholder addSubview: date_short];
        [imgholder addSubview: delete];
        [imgholder addSubview: download];
        [imgholder addSubview: copy_url];
        [imgholder addSubview: open_in_new];
        [imgholder addSubview: index_view];
        
        [scrollview_.documentView addSubview: imgholder];
    });
}

- (void) makeScrollViewCells:(NSArray *)arr
{
    __block int l = (int)arr.count;
    int c = l;
    pic_list_ = arr;

    // find if we have fitting entries in the frame of 500
    Boolean compromise = false;
    if (c < 4)
    {
        compromise = true;
    }

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    while (l--)
    {
        NSArray *curr = arr[ l ];

        NSString *url = curr[ 0 ];
        // NSString *key = curr[ 1 ];
        NSString *date = curr[ 2 ];
        NSNumber *timestamp = curr[ 3 ];

        NSImageView *imageView = [[NSImageView alloc] initWithFrame:CGRectMake (10.0f, 10.0f, 130.0f, 130.0f)];

        int origin_y = ((c - (l + 1)) * 150);
        if (compromise) origin_y = 350 - (l * 150);
        NSView *imgholder = [[NSView alloc] initWithFrame: CGRectMake (0.0f, origin_y, 500.0f, 140.0f)];

        [self setImageTo: imageView withURL: url];
        [self createEntryToImageView: imageView andImgHolder: imgholder
                            andIndex: l
                             andDate: date
                        andTimestamp: timestamp];
    }
    });

    int h = c * 150;
    if (h < 500) h = 500;

    [scrollview_.documentView setFrame: NSMakeRect (0,0, 500.0f, h)];
    NSPoint newScrollOrigin = NSMakePoint (0.0,NSMaxY ([[scrollview_ documentView] frame])
                                          -NSHeight ([[scrollview_ contentView] bounds]));

    [[scrollview_ contentView] scrollToPoint: newScrollOrigin];
}

- (void)downloadImage:(NSButton *)button
{
    int index = (int)button.tag;
    NSArray *arr = pic_list_[ index ];

    // find image from parent node
    NSArray *views = [button.superview subviews];
    NSImage *img = nil;
    for (NSView *view in views)
    {
        if ([view isMemberOfClass:[NSImageView class]])
        {
            img = ((NSImageView *)view).image;
            break;
        }
    }

    NSString *stringURL = arr[ 0 ];
    NSString *title = [@"FIM_" stringByAppendingString:arr[ 2 ]];
    title = [title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    title = [title stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    title = [title stringByAppendingString:@".jpg"];
    
    [NetWorking downloadImage: stringURL withTitle: title onSuccess:^(NSString *filepath) {
        [Notifs showDownloadNotification: filepath andImage: img];
    }];

    [self closeWindow];
}

- (void)copyImageUrl:(NSButton *)button
{
    NSArray *arr = pic_list_[ button.tag ];
    NSString *stringurl = arr[ 0 ];

    main_view_.alphaValue = 0.0f;

    // create "copied to clipboard label"
    
    CGRect mframe = main_view_.frame;

    __block NSTextView *copied_view = [[NSTextView alloc] initWithFrame: CGRectMake (mframe.origin.x + 120.0f, mframe.origin.y + 400.0f, 250.f, 52.0f)];
    copied_view.editable = NO;
    copied_view.alignment = NSTextAlignmentCenter;
    copied_view.backgroundColor = [NSColor whiteColor];
    copied_view.string = @"\nImage URL Copied to Clipboard!!";
    copied_view.font = [NSFont fontWithName:@"HelveticaNeue-Thin" size:15.0f];
    
    [window_.contentView addSubview: copied_view];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [copied_view removeFromSuperview];
        copied_view = nil;

        [self closeWindow];
    });
    
    [NetWorking copyImageUrl: stringurl];
}

-(NSString *)dateDiff:(NSNumber *)unix_timestamp
{
    NSDate *convertedDate = [NSDate dateWithTimeIntervalSince1970: [unix_timestamp doubleValue]];

    NSDate *todayDate = [NSDate date];
    double ti = [convertedDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
        return @"never";
    } else  if (ti < 60) {
        return @"less than a minute ago";
    } else if (ti < 3600) {
        int diff = round(ti / 60);
        return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (ti < 86400) {
        int diff = round(ti / 60 / 60);
        return[NSString stringWithFormat:@"%d hours ago", diff];
    } else if (ti < 2629743) {
        int diff = round(ti / 60 / 60 / 24);
        return[NSString stringWithFormat:@"%d days ago", diff];
    } else {
        return @"never";
    }
}

- (void)deleteImage:(NSButton *)button
{
    [self closeWindow];
    if (is_deleting_image_) return ;

    int index = (int)button.tag;
    NSArray *arr = pic_list_[ index ];

    NSString *uid_orig = [arr[ 0 ] lastPathComponent];
    NSString *uid = [uid_orig stringByDeletingPathExtension];

    NSString *key = [arr[ 1 ] stringByAppendingString:@"&e="];
    key = [key stringByAppendingString:uid];
    
    is_deleting_image_ = YES;

    [NetWorking deleteImage: key onSuccess:^{
        [Storage deletePictureWithIndex: index];
        [ImgCache deleteFileWithURL: uid_orig];
        
        [Notifs showDeleteNotification];
        
        is_deleting_image_ = NO;

        dispatch_sync (dispatch_get_main_queue(), ^{
            NSArray *arr = [Storage readPicturesFromCache];
            if (!arr) return ;
            pic_list_ = arr;

            if (self.Visible)
            {
                NSArray *subviews = [scrollview_.documentView subviews];
                if (subviews && subviews.count > index)
                {
                    [subviews [index] removeFromSuperview];
                }
            }
        });

    } onError:^(NSError *err) {
        is_deleting_image_ = NO;
        // NSLog (@"show error and add back to user defaults");
        
        if (err)
            [Notifs showErrorNotification];
        else
        {
            [Notifs showDeleteNotification];
            [Storage deletePictureWithIndex: index];
            [ImgCache deleteFileWithURL: uid_orig];

            NSArray *arr = [Storage readPicturesFromCache];
            if (!arr) return ;
            pic_list_ = arr;
        }
    }];
}

- (void)openImage:(NSImageView *)imgView
{
    NSArray *arr = pic_list_[ imgView.tag ];
    NSString *str = arr[ 0 ];
    
    [self closeWindow];

    [NetWorking openURL: str];
}

- (void)closeWindow
{
    self.Visible = NO;
    [bg_overlay_ removeFromSuperview];
    bg_overlay_ = nil;

    [main_view_ removeFromSuperview];
    main_view_ = nil;
    
    nothing_here_ = nil;

    [self close];
}

@end
