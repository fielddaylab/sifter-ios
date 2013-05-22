//
//  InnovNavController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>

@class InnovSettingsView;

@interface InnovNavController : UINavigationController <UISearchBarDelegate>
{
    UIButton *switchButton;
    UIBarButtonItem *switchViewsBarButton;
    UISearchBar *searchBar;
    UIBarButtonItem *settingsBarButton;
    
    InnovSettingsView *settingsView;
}

@end
