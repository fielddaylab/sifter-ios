//
//  CameraOverlay.h
//  YOI
//
//  Created by Jacob Hanshaw on 8/8/13.
//
//

#define BUTTON_Y_OFFSET      10
#define BUTTON_WIDTH         78
#define BUTTON_HEIGHT        35
#define BUTTON_CORNER_RADIUS 15.0f
#define BUTTON_IMAGE_NAME    @"camera_roll.png"

@protocol CameraOverlayDelegate <NSObject>
- (void) showLibraryButtonPressed: (id) sender;
@end

@interface CameraOverlay : UIView
@property (nonatomic) UIButton *libraryButton;

- (id)initWithFrame:(CGRect)frame andDelegate:(id) delegate;

@end