#import "ScreenshotCropper.h"

@interface DrawCGImageRefView : NSView

@property (nonatomic) CGImageRef imgref;
@property (weak, nonatomic) ScreenshotCropper *parent_;

@end

@implementation DrawCGImageRefView

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextDrawImage ([[NSGraphicsContext currentContext]
                         graphicsPort], dirtyRect, self.imgref);
}

- (void)dealloc
{
    if (self.imgref) CFRelease (self.imgref);
}

- (BOOL)acceptsFirstResponder
{
    return (YES);
}

- (void)mouseDragged:(NSEvent *)event
{
    [self.parent_ _mouseDragged:event];
    [super mouseDragged:event];
}

- (void)mouseDown:(NSEvent *)event
{
    [self.parent_ _mouseDown:event];
    [super mouseDown:event];
}
- (void)mouseUp:(NSEvent *)event
{
    [self.parent_ _mouseUp:event];
    [super mouseUp:event];
}
- (BOOL) becomeFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    [self.parent_ _keyDown:event];
    [super keyDown:event];
}

@end

@interface ScreenshotCropper ()
{
    DrawCGImageRefView *imgview_;
    Boolean is_dragging_;
    CGPoint start_point_, end_point_;
}

@end

@implementation ScreenshotCropper
{
    NSWindow *window_;
    NSView *crop_view_;
    void(^success_)(CGImageRef imgref);
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    window_ = window;
    window_.releasedWhenClosed = NO;

    start_point_ = CGPointMake (-1.0f, -1.0f);
    end_point_ = start_point_;

    NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
                                     NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:window_.frame
                                                        options:options
                                                          owner:self
                                                       userInfo:nil];
    [window_.contentView addTrackingArea:area];
    window_.acceptsMouseMovedEvents = YES;

    return (self);
}

- (void)_mouseDown:(NSEvent *)event
{
    crop_view_.hidden = NO;
    is_dragging_ = YES;
    start_point_ = [imgview_ convertPoint:[event locationInWindow] fromView:nil];
    end_point_ = start_point_;
    crop_view_.frame = CGRectMake (start_point_.x, start_point_.y,
                                   0.0f, 0.0f);
}


- (void)_mouseDragged:(NSEvent *)event
{
    end_point_ = [imgview_ convertPoint:[event locationInWindow] fromView:nil];
    
    float start_x = start_point_.x;
    float start_y = start_point_.y;
    float end_x = end_point_.x - start_point_.x;
    float end_y = end_point_.y - start_point_.y;
    
    if (end_x < 0)
    {
        start_x = end_point_.x;
        end_x = start_point_.x - start_x;
    }

    if (end_y < 0)
    {
        start_y = end_point_.y;
        end_y = start_point_.y - start_y;
    }

    crop_view_.frame = CGRectMake (start_x, start_y,
                                   end_x, end_y);
}

- (void)_mouseUp:(NSEvent *)event
{
    if (!is_dragging_) return ;

    is_dragging_ = NO;
    crop_view_.hidden = YES;

    if ((fabs (start_point_.x - end_point_.x) > 18.0f || fabs (start_point_.y - end_point_.y) > 18.0f) && end_point_.x > -1.0f)
    {
        CGRect crop_rect = crop_view_.frame;
        crop_rect.origin.y *= [window_ backingScaleFactor];
        crop_rect.origin.x *= [window_ backingScaleFactor];
        crop_rect.size.width *= [window_ backingScaleFactor];
        crop_rect.size.height *= [window_ backingScaleFactor];
        
        crop_rect.origin.y = CGImageGetHeight (imgview_.imgref) - crop_rect.origin.y;
        crop_rect.origin.y -= crop_rect.size.height;

        CGImageRef cropped_image = CGImageCreateWithImageInRect (imgview_.imgref, crop_rect);
        if (success_) success_ (cropped_image);
    }
    else if (success_) success_ (NULL);

    success_ = nil;
}

- (void)_keyDown:(NSEvent *)event
{
    switch ([event keyCode]) {
        case 51:
        case 53:    // ESCAPE
            is_dragging_ = NO;
            if (success_)
                success_ (NULL);
            
            success_ = nil;
            break;
        
        case 49:
        case 36:    // CANCEL DRAGGING
            is_dragging_ = NO;
            crop_view_.hidden = YES;
            start_point_ = CGPointMake (-1.0f, -1.0f);
            end_point_ = start_point_;

            // 16ms later change the cursor
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.016f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSCursor crosshairCursor] set];
            });

            break;
        default:
            break;
    }
}

- (void)showWindow:(id)sender
{
    [window_ makeKeyAndOrderFront:self];
    window_.level = 1000;

    // 50ms later change the cursor
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSCursor crosshairCursor] set];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.026f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSCursor crosshairCursor] set];
        });
    });

    [super showWindow:sender];
}

- (void)drawImg:(CGImageRef)imgref onSuccess:(void(^)(CGImageRef imgref))success
{
    success_ = success;

    CGRect frame = window_.frame;
    frame.origin.x = 0; frame.origin.y = 0;
    imgview_ = [[DrawCGImageRefView alloc] initWithFrame:frame];
    imgview_.imgref = imgref;
    imgview_.parent_ = self;

    while (window_.contentView.subviews.count > 0)
        [[window_.contentView.subviews lastObject] removeFromSuperview];

    [window_.contentView addSubview:imgview_];

    crop_view_ = [[NSView alloc] initWithFrame: CGRectZero];
    [crop_view_ setWantsLayer:YES];
    crop_view_.alphaValue = 0.3f;
    crop_view_.layer.borderWidth = 1.0f;
    crop_view_.layer.borderColor = [NSColor darkGrayColor].CGColor;
    crop_view_.layer.backgroundColor = [NSColor blueColor].CGColor;

    [window_.contentView addSubview:crop_view_];
    [imgview_ becomeFirstResponder];
}

- (void)close
{
    if (imgview_.imgref) CFRelease (imgview_.imgref);
    imgview_.imgref = nil;

    while (window_.contentView.subviews.count > 0)
        [[window_.contentView.subviews lastObject] removeFromSuperview];

    [[NSCursor arrowCursor] set];
    [super close];
}

@end
