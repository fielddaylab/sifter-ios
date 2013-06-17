//
//  InnovCommentCell.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/17/13.
//
//

#import "InnovCommentCell.h"

@implementation InnovCommentCell

@synthesize textView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect textframe = self.frame;
        textframe.origin.x = 0;
        textframe.origin.y = 0;
        textView = [[UITextView alloc] initWithFrame:textframe];
        textView.editable = NO;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        [self addSubview:textView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
