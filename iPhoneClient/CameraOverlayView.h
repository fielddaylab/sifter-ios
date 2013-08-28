//
//  CameraOverlayView.h
//  YOI
//
//  Created by Jacob Hanshaw on 8/26/13.
//
//

@protocol CameraOverlayViewDelegate <NSObject>
@required
- (void)showLibraryButtonPressed:(id)sender;
@end

#define BUTTON_WIDTH         40
#define BUTTON_HEIGHT        BUTTON_WIDTH
#define BUTTON_PADDING       15

@interface CameraOverlayView : UIView
- (id)initWithFrame:(CGRect)frame andDelegate:(id<CameraOverlayViewDelegate>) delegate;
@end