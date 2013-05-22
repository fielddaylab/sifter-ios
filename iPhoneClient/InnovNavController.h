//
//  InnovNavController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>
#import "InnovSettingsView.h"

@class InnovSettingsView;

@interface InnovNavController : UINavigationController <UISearchBarDelegate, InnovSettingsViewDelegate>
{
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovSettingsView *settingsView;
}

@end
