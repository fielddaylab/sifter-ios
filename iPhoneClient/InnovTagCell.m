//
//  InnovTagCell.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/18/13.
//
//

#import "InnovTagCell.h"

#define IMAGE_HEIGHT 35
#define IMAGE_WIDTH 35
#define SPACING 10

@implementation InnovTagCell

@synthesize mediaImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        mediaImageView = [[AsyncMediaImageView alloc] initWithFrame:CGRectMake(SPACING, (self.frame.size.height - IMAGE_HEIGHT)/2, IMAGE_WIDTH, IMAGE_HEIGHT)];
        [mediaImageView setSpinnerColor:[UIColor blackColor]];
        [self addSubview:mediaImageView];
        
        self.textLabel.frame = CGRectMake(SPACING + IMAGE_WIDTH + SPACING, 0, self.frame.size.width - (SPACING + IMAGE_WIDTH + SPACING), self.frame.size.height);
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
