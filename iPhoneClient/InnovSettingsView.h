//
//  SettingsView.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import <UIKit/UIKit.h>

#import "InnovDisplayProtocol.h"

@protocol InnovSettingsViewDelegate <NSObject>

@required
- (void) showProfile;
- (void) link;
- (void) showAbout;

@end

@interface InnovSettingsView : UIView <InnovDisplayProtocol>
{
    __weak IBOutlet UIButton *profileButton;
    __weak IBOutlet UIButton *createLinkButton;
    __weak IBOutlet UIButton *notificationsButton;
    __weak IBOutlet UIButton *aboutButton;
    
    BOOL hiding;

}

@property(nonatomic, weak) id<InnovSettingsViewDelegate> delegate;

@end