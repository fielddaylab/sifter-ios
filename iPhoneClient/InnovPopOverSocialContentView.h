//
//  InnovPopOverSocialContentView.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

@class Note;

#import "CustomBadge.h"

#warning CHANGE TWITTER HANDLE
#define DEFAULT_TITLE                @"Note"
#define TWITTER_HANDLE               @"@y_o_i"

@protocol InnovPopOverSocialContentViewDelegate <NSObject>
@required
- (void) mailButtonPressed:      (id) sender;
- (void) twitterButtonPressed:   (id) sender;
- (void) facebookButtonPressed:  (id) sender;
- (void) pinterestButtonPressed: (id) sender;
@end

@interface InnovPopOverSocialContentView : UIView

@property(nonatomic) Note *note;

@property(weak, nonatomic) IBOutlet UILabel *shareLabel;
@property(weak, nonatomic) IBOutlet UIButton *facebookButton;
@property(nonatomic) CustomBadge *facebookBadge;
@property(weak, nonatomic) IBOutlet UIButton *twitterButton;
@property(nonatomic) CustomBadge *twitterBadge;
@property(weak, nonatomic) IBOutlet UIButton *pinterestButton;
@property(nonatomic) CustomBadge *pinterestBadge;
@property(weak, nonatomic) IBOutlet UIButton *emailButton;
@property(nonatomic) CustomBadge *emailBadge;

- (void) refreshBadges;

@end