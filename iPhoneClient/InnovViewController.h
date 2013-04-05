//
//  InnovViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIActionSheet.h>
#import "AppModel.h"
#import "Location.h"
#import "Annotation.h"
#import "AnnotationView.h"
#import "Note.h"

@interface InnovViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, UIActionSheetDelegate, UISearchBarDelegate> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    IBOutlet UIView *contentView;
    IBOutlet UIView *mapContentView;
    IBOutlet UIView *listContentView;
    IBOutlet MKMapView *mapView;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UIBarButtonItem *settingsBarButton;
    UISearchBar *searchBarTop;
    
    BOOL tracking;
    BOOL appSetNextRegionChange;
    NSTimer *refreshTimer;
    NSMutableArray *locationsToAdd;
    NSMutableArray *locationsToRemove;
    
    Note *note;
}

@property(nonatomic)Note *note;

- (void)switchViews;
- (void)settingsPressed;
- (IBAction)showTagsPressed:(id)sender;
- (IBAction)cameraPressed:(id)sender;
- (IBAction)trackingButtonPressed:(id)sender;

@end
