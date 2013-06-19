//
//  InnovNoteCell.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/18/13.
//
//

#import "InnovNoteCell.h"

#define IMAGE_X_MARGIN      0
#define IMAGE_Y_MARGIN      0

#define BUTTON_WIDTH        36
#define BUTTON_HEIGHT       36

@implementation InnovNoteCell

@synthesize imageView, usernameLabel, flagButton, playButton, likeButton, shareButton, captionTextView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id<InnovNoteCellDelegate>) delegate
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        imageView       = [[AsyncMediaImageView alloc] init];
        imageView.frame = CGRectMake(IMAGE_X_MARGIN,
                                     IMAGE_Y_MARGIN,
                                     self.frame.size.width - 2 * IMAGE_X_MARGIN,
                                     self.frame.size.width - 2 * IMAGE_X_MARGIN);
        [self addSubview:imageView];
        
        usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                  IMAGE_Y_MARGIN + imageView.frame.size.height,
                                                                  self.frame.size.width - 4 * BUTTON_WIDTH,
                                                                  BUTTON_HEIGHT)];
        usernameLabel.backgroundColor = [UIColor blackColor];
        usernameLabel.textColor       = [UIColor whiteColor];
        [self addSubview:usernameLabel];
        
        playButton  = [[UIButton alloc] initWithFrame:CGRectMake(usernameLabel.frame.size.width,
                                                                 IMAGE_Y_MARGIN + imageView.frame.size.height,
                                                                 BUTTON_WIDTH,
                                                                 BUTTON_HEIGHT)];
        playButton.backgroundColor = [UIColor blackColor];
        [playButton setTitle:@"PL" forState:UIControlStateNormal];
        [playButton setTitle:@"PL" forState:UIControlStateHighlighted];
        [playButton addTarget:delegate action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:playButton];
        
        flagButton  = [[UIButton alloc] initWithFrame:CGRectMake(playButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
        flagButton.backgroundColor = [UIColor blackColor];
        [flagButton setTitle:@"F" forState:UIControlStateNormal];
        [flagButton setTitle:@"F" forState:UIControlStateHighlighted];
        [flagButton addTarget:delegate action:@selector(flagButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:flagButton];
        
        likeButton  = [[UIButton alloc] initWithFrame:CGRectMake(flagButton.frame.origin.x  + BUTTON_WIDTH, IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
        likeButton.backgroundColor = [UIColor blackColor];
        [likeButton setImage:[UIImage imageNamed:@"thumbs_up.png"] forState:UIControlStateNormal];
        [likeButton setImage:[UIImage imageNamed:@"thumbs_up_selected.png"] forState:UIControlStateSelected];
        [likeButton addTarget:delegate action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        likeButton.titleLabel.center = likeButton.center;
        likeButton.imageView.center  = likeButton.center;
        [self addSubview:likeButton];
        
        shareButton = [[UIButton alloc] initWithFrame:CGRectMake(likeButton.frame.origin.x + BUTTON_WIDTH,  IMAGE_Y_MARGIN + imageView.frame.size.height, BUTTON_WIDTH, BUTTON_HEIGHT)];
        shareButton.backgroundColor = [UIColor blackColor];
        [shareButton setTitle:@"S" forState:UIControlStateNormal];
        [shareButton setTitle:@"S" forState:UIControlStateHighlighted];
        [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:shareButton];
        
        captionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, IMAGE_Y_MARGIN + imageView.frame.size.height + BUTTON_HEIGHT, self.frame.size.width, BUTTON_HEIGHT)];
        captionTextView.userInteractionEnabled = NO;
        [self addSubview:captionTextView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
