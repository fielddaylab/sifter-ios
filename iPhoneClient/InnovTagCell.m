//
//  InnovTagCell.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/18/13.
//
//

#import "InnovTagCell.h"

@implementation InnovTagCell

@synthesize mediaImageView, tagLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        mediaImageView = [[AsyncMediaImageView alloc] initWithFrame:CGRectMake(SPACING, (self.frame.size.height - TAG_CELL_IMAGE_HEIGHT)/2, TAG_CELL_IMAGE_WIDTH, TAG_CELL_IMAGE_HEIGHT)];
        [mediaImageView setSpinnerColor:[UIColor blackColor]];
        [self addSubview:mediaImageView];
        
        tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(SPACING + TAG_CELL_IMAGE_WIDTH + SPACING, 0, self.frame.size.width - (SPACING + TAG_CELL_IMAGE_WIDTH + SPACING), self.frame.size.height)];
        tagLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:tagLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
