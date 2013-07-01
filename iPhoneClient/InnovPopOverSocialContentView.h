//
//  InnovPopOverSocialContentView.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

@class Note;

@protocol InnovPopOverSocialContentViewDelegate <NSObject>
@required
- (void) mailButtonPressed:      (id) sender;
- (void) twitterButtonPressed:   (id) sender;
- (void) facebookButtonPressed:  (id) sender;
- (void) pinterestButtonPressed: (id) sender;
@end

@interface InnovPopOverSocialContentView : UIView

@property(nonatomic) Note *note;

- (void) refreshBadges;

@end
