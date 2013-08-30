//
//  CameraOverlayView.m
//  YOI
//
//  Created by Jacob Hanshaw on 8/26/13.
//
//

#import "CameraOverlayView.h"

#import <AssetsLibrary/AssetsLibrary.h>

#define ANIMATE_DURATION     0.5
#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@interface CameraOverlayView()
{
    id<CameraOverlayViewDelegate> delegate;
    
    UIButton *libraryButton;
    UIActivityIndicatorView *spinner;
}

@end

@implementation CameraOverlayView

- (id)initWithFrame:(CGRect)frame andDelegate:(id<CameraOverlayViewDelegate>) aDelegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = NO;
        
        delegate = aDelegate;
        
        CGRect libraryFrame = frame;
        libraryFrame.origin.x = frame.size.width - BUTTON_WIDTH - BUTTON_PADDING;
        libraryFrame.origin.y = 0;
        libraryFrame.size.width = BUTTON_WIDTH;
        
        libraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        libraryButton.frame = libraryFrame;
        [libraryButton addTarget:self action:@selector(showLibraryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:libraryButton];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = libraryButton.center;
        [libraryButton addSubview:spinner];
        [spinner startAnimating];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
        
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                     usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                         if (nil != group) {
                                             // be sure to filter the group so you only get photos
                                             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                                             
                                             if(group.numberOfAssets > 0)
                                             {
                                                 [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1]
                                                                         options:0
                                                                      usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                                          if (nil != result) {
                                                                              ALAssetRepresentation *repr = [result defaultRepresentation];
                                                                              // this is the most recent saved photo
                                                                              UIImage *img = [UIImage imageWithCGImage:[repr fullResolutionImage]];
                                                                              // we only need the first (most recent) photo -- stop the enumeration
                                                                              [spinner removeFromSuperview];
                                                                              [libraryButton setImage:img forState:UIControlStateNormal];
                                                                              libraryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                                                                              *stop = YES;
                                                                          }
                                                                      }];
                                             }
                                             //      else
                                             //          [spinner removeFromSuperview];
                                         }
                                         
                                         *stop = NO;
                                     } failureBlock:^(NSError *error) {
                                         [spinner removeFromSuperview];
                                         NSLog(@"error: %@", error);
                                     }];
    }
    return self;
}

- (void) dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showLibraryButtonPressed:(id)sender
{
    [delegate showLibraryButtonPressed:self];
    [self removeFromSuperview];
}

- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //Ignoring specific orientations
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown)
        return;
    
    [UIView animateWithDuration:ANIMATE_DURATION delay:0.0f options:UIViewAnimationCurveEaseIn animations:^
     {
         float degrees;
         if(orientation == UIDeviceOrientationLandscapeLeft)
         {
             CGAffineTransform rotationTransform = CGAffineTransformIdentity;
             rotationTransform = CGAffineTransformRotate(rotationTransform, DegreesToRadians(0));
             libraryButton.transform = rotationTransform;
             libraryButton.frame = CGRectMake(BUTTON_PADDING, 0, BUTTON_WIDTH, BUTTON_HEIGHT);
             
             degrees = 90;
         }
         else
         {
             CGAffineTransform rotationTransform = CGAffineTransformIdentity;
             rotationTransform = CGAffineTransformRotate(rotationTransform, DegreesToRadians(0));
             libraryButton.transform = rotationTransform;
             libraryButton.frame = CGRectMake(self.frame.size.width - BUTTON_WIDTH - BUTTON_PADDING, 0, BUTTON_WIDTH, BUTTON_HEIGHT);
             
             if (orientation == UIDeviceOrientationPortrait)
                 degrees = 0;
             else if (orientation == UIDeviceOrientationLandscapeRight)
                 degrees = 270;
             else
                 degrees = 180;
         }
         
         CGAffineTransform rotationTransform = CGAffineTransformIdentity;
         rotationTransform = CGAffineTransformRotate(rotationTransform, DegreesToRadians(degrees));
         libraryButton.transform = rotationTransform;
     } completion:nil];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end