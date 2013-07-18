//
//  InnovTagCell.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/18/13.
//
//

#import "InnovTagCell.h"

@implementation InnovTagCell

@synthesize mediaImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        mediaImageView = [[AsyncMediaImageView alloc] initWithFrame:self.imageView.frame];
        [self addSubview:mediaImageView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
