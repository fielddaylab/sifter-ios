//
//  InnovCommentCell.h
//  YOI
//
//  Created by JacobJamesHanshaw on 6/17/13.
//
//

#define AUTHOR_ROW_HEIGHT 36

@protocol InnovCommentCellDelegate <NSObject>
@required
-(void) deleteButtonPressed:(UIButton *)sender;
-(void) presentLogIn;
@end

@class Note;

@interface InnovCommentCell : UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier andDelegate:(id<InnovCommentCellDelegate>) aDelegate;
-(void) updateWithNote:(Note *) aNote andIndex:(int) index;

@end