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

@interface CameraOverlayView : UIView
- (id)initWithFrame:(CGRect)frame andDelegate:(id<CameraOverlayViewDelegate>) delegate;
@end