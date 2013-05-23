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

@property(nonatomic, weak) id<InnovSettingsViewDelegate> delegate;

@end