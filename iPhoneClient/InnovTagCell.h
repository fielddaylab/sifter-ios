//
//  InnovTagCell.h
//  YOI
//
//  Created by Jacob Hanshaw on 7/18/13.
//
//

#import "AsyncMediaImageView.h"

#define TAG_CELL_IMAGE_HEIGHT 35
#define TAG_CELL_IMAGE_WIDTH 35
#define SPACING 10

@interface InnovTagCell : UITableViewCell

@property(nonatomic) AsyncMediaImageView *mediaImageView;
@property(nonatomic) UILabel *tagLabel;

@end