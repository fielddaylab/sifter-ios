//
//  SettingsView.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>

@interface InnovSettingsView : UIView
{
    __weak IBOutlet UIButton *profileButton;
    __weak IBOutlet UIButton *createLinkButton;
    __weak IBOutlet UIButton *notificationsButton;
    __weak IBOutlet UIButton *aboutButton;
    
    BOOL hiding;

}

- (IBAction)profileButtonPressed:           (id)sender;
- (IBAction)createLinkButtonPressed:        (id)sender;
- (IBAction)notificationsButtonPressed:     (id)sender;
- (IBAction)aboutButtonPressed:             (id)sender;

@end