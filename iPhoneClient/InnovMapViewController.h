//
//  InnovMapViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol InnovPresentNoteDelegate;

@protocol InnovMapViewDelegate <NSObject>
@required
-(void) stoppedTracking;
@end

@interface InnovMapViewController : UIViewController

@property(nonatomic, weak) id<InnovMapViewDelegate, InnovPresentNoteDelegate> delegate;

- (void) toggleTracking;
- (void) updatePlayerLocation;
- (void) zoomAndCenterMapAnimated:(BOOL) animated;

@end