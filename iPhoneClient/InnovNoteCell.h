//
//  InnovNoteCell.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/18/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncMediaImageView.h"

@protocol InnovNoteCellDelegate <NSObject>
@required
- (void) playButtonPressed: (id) sender;
- (void) flagButtonPressed: (id) sender;
- (void) likeButtonPressed: (id) sedner;
@end

@interface InnovNoteCell : UITableViewCell

@property(nonatomic) AsyncMediaImageView *imageView;
@property(nonatomic) UILabel  *usernameLabel;
@property(nonatomic) UIButton *flagButton;
@property(nonatomic) UIButton *playButton;
@property(nonatomic) UIButton *likeButton;
@property(nonatomic) UIButton *shareButton;
@property(nonatomic)  UITextView *captionTextView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id<InnovNoteCellDelegate>) delegate;

@end
