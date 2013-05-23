//
//  InnovViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 3/25/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovPresentNoteProtocol.h"

@class TMQuiltView, InnovSettingsView, InnovMapViewController, InnovSelectedTagsViewController, Note, CLLocation;

@interface InnovViewController : UIViewController <UISearchBarDelegate, InnovPresentNoteProtocol> {
    
    __weak IBOutlet UIButton *showTagsButton;
    __weak IBOutlet UIButton *trackingButton;
    
    IBOutlet UIView *contentView;
    TMQuiltView *quiltView;
    
    CLLocation *lastLocation;
    NSTimer *refreshTimer;
    
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovSettingsView *settingsView;
    InnovMapViewController *mapVC;
    InnovSelectedTagsViewController *selectedTagsVC;
    
    NSMutableArray *locationsToAdd;
    NSMutableArray *locationsToRemove;
    
    NSMutableArray *availableTags;
    NSMutableDictionary   *tagNotesDictionary;
    
    NSMutableArray *images;
    NSMutableArray *text;
    
    Note *noteToAdd;
}

@property (nonatomic) CLLocation *lastLocation;
@property (nonatomic) Note *noteToAdd;

@end
