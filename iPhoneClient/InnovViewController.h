//
//  InnovViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AppModel.h"
#import "Location.h"
#import "Annotation.h"
#import "AnnotationView.h"
#import "InnovSelectedTagsViewController.h"
#import "InnovNoteEditorViewController.h"
#import "Note.h"
#import "MapNotePopUp.h"
#import "InnovSettingsView.h"

@class TMQuiltView;

@interface InnovViewController : UIViewController < MKMapViewDelegate, UISearchBarDelegate, InnovSelectedTagsDelegate, InnovSettingsViewDelegate> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    IBOutlet UIView *contentView;
    IBOutlet UIView *mapContentView;
    IBOutlet UIView *listContentView;
    IBOutlet MKMapView *mapView;
    TMQuiltView *quiltView;
    
    BOOL hidingPopUp;
    
    BOOL tracking;
    BOOL isLocal;
    CLLocation *madisonCenter;
    CLLocation *lastLocation;
    BOOL appSetNextRegionChange;
    NSTimer *refreshTimer;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovSettingsView *settingsView;

    NSMutableArray *locationsToAdd;
    NSMutableArray *locationsToRemove;
    
    NSMutableArray *availableTags;
    NSMutableDictionary   *tagNotesDictionary;
    
    NSMutableArray *images;
    NSMutableArray *text;
    
    Note *noteToAdd;
    
    IBOutlet MapNotePopUp *notePopUp;
    InnovSelectedTagsViewController *selectedTagsVC;
    InnovNoteEditorViewController *editorVC;
}

@property (readwrite) BOOL isLocal;
@property (nonatomic) CLLocation *lastLocation;
@property (nonatomic) Note *noteToAdd;

- (void)switchViews;

@end
