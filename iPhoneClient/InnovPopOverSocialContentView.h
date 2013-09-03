//
//  InnovPopOverSocialContentView.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/19/13.
//
//

@class Note;

#import "InnovPopOverContentView.h"

#warning CHANGE TWITTER HANDLE
#define DEFAULT_TITLE                @"Note"
#define TWITTER_HANDLE               @"@SiftrMadison"

@protocol InnovPopOverSocialContentViewDelegate <NSObject>
@required
- (void) mailButtonPressed:      (id) sender;
- (void) twitterButtonPressed:   (id) sender;
- (void) facebookButtonPressed:  (id) sender;
- (void) pinterestButtonPressed: (id) sender;
@end

@interface InnovPopOverSocialContentView : InnovPopOverContentView

@property(nonatomic) Note *note;

@property(weak, nonatomic) IBOutlet UIButton *facebookButton;
@property(weak, nonatomic) IBOutlet UIButton *twitterButton;
@property(weak, nonatomic) IBOutlet UIButton *pinterestButton;
@property(weak, nonatomic) IBOutlet UIButton *emailButton;

- (void) refreshNote;

@end