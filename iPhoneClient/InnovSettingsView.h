//
//  SettingsView.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovDisplayProtocol.h"

@protocol InnovSettingsViewDelegate <NSObject>
@required
- (void) showAbout;
- (void) presentLogIn;
@end

@interface InnovSettingsView : UIView <InnovDisplayProtocol>

@property(nonatomic, weak) id<InnovSettingsViewDelegate> delegate;

@end