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
#import "InnovSelectedTagsViewController.h"
#import "InnovNoteEditorViewController.h"
#import "Note.h"
#import "MapNotePopUp.h"

@interface InnovViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, UIActionSheetDelegate, UISearchBarDelegate, InnovSelectedTagsDelegate> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    IBOutlet UIView *contentView;
    IBOutlet UIView *mapContentView;
    IBOutlet UIView *listContentView;
    IBOutlet MKMapView *mapView;
    IBOutlet UITableView *tableView;
    IBOutlet UIView *settingsView;
    
    BOOL hidingSettings;
    BOOL hidingPopUp;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UIBarButtonItem *settingsBarButton;
    UISearchBar *searchBarTop;
    
    BOOL tracking;
    BOOL isLocal;
    CLLocation *madisonCenter;
    CLLocation *lastLocation;
    BOOL appSetNextRegionChange;
    NSTimer *refreshTimer;
    NSMutableArray *locationsToAdd;
    NSMutableArray *locationsToRemove;
    
    Note *noteToAdd;
    
    IBOutlet MapNotePopUp *notePopUp;
    
    InnovSelectedTagsViewController *selectedTagsVC;
    
    InnovNoteEditorViewController *editorVC;
}

@property (readwrite) BOOL isLocal;
@property (nonatomic) CLLocation *lastLocation;
@property (nonatomic) Note *noteToAdd;

- (void)switchViews;
- (void)settingsPressed;
- (IBAction)showTagsPressed:(id)sender;
- (IBAction)cameraPressed:(id)sender;
- (IBAction)trackingButtonPressed:(id)sender;
- (IBAction)presentNote:(id)sender;
- (IBAction)createLinkPressed:(id)sender;
- (IBAction)notificationsPressed:(id)sender;
- (IBAction)autoPlayPressed:(id)sender;
- (IBAction)aboutPressed:(id)sender;


@end
