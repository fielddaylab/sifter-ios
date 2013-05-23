//
//  InnovMapViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "InnovPresentNoteProtocol.h"

@class  MapNotePopUp;

@interface InnovMapViewController : UIViewController <MKMapViewDelegate, InnovPresentNoteProtocol>

{
    IBOutlet MKMapView *mapView;
    MapNotePopUp *notePopUp;
    
    BOOL isLocal;
    BOOL tracking;
    BOOL appSetNextRegionChange;
    
    CLLocation *madisonCenter;
}

@property(nonatomic, weak) id<InnovPresentNoteProtocol> delegate;

- (void) toggleTracking;
- (void) updatePlayerLocation;
- (void) zoomAndCenterMapAnimated:(BOOL) animated;

@end
