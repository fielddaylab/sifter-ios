//
//  InnovCommentCell.m
//  YOI
//
//  Created by JacobJamesHanshaw on 6/17/13.
//
//

#import "InnovCommentCell.h"

#import "AppModel.h"
#import "AppServices.h"
#import "Note.h"

#define BUTTON_HEIGHT       AUTHOR_ROW_HEIGHT
#define BUTTON_WIDTH        BUTTON_HEIGHT

@interface InnovCommentCell()
{
    UILabel    *usernameLabel;
    UIButton   *deleteButton;
    UIButton   *flagButton;
    UIButton   *likeButton;
    UITextView *textView;
    
    id<InnovCommentCellDelegate> delegate;
    
    Note *note;
}

@end

@implementation InnovCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier andDelegate:(id<InnovCommentCellDelegate>) aDelegate
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        delegate = aDelegate;
        
        usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-BUTTON_WIDTH*3, BUTTON_HEIGHT)];
        [self addSubview:usernameLabel];
        
        deleteButton  = [[UIButton alloc] initWithFrame:CGRectMake(usernameLabel.frame.size.width, 0, BUTTON_WIDTH, BUTTON_HEIGHT)];
        [deleteButton addTarget:delegate action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [deleteButton setImage:[UIImage imageNamed:@"deleteComment.png"] forState:UIControlStateNormal];
        [deleteButton setImage:[UIImage imageNamed:@"deleteComment.png"] forState:UIControlStateHighlighted];
        [self addSubview:deleteButton];
        
        flagButton  = [[UIButton alloc] initWithFrame:CGRectMake(deleteButton.frame.origin.x + BUTTON_WIDTH, 0, BUTTON_WIDTH, BUTTON_HEIGHT)];
        [flagButton addTarget:self action:@selector(flagButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [flagButton setImage:[UIImage imageNamed:@"flagBlack.png"] forState:UIControlStateNormal];
        [flagButton setImage:[UIImage imageNamed:@"flagRed.png"] forState:UIControlStateSelected];
        [flagButton setImage:[UIImage imageNamed:@"flagRed.png"] forState:UIControlStateHighlighted];
        [self addSubview:flagButton];
        
        likeButton  = [[UIButton alloc] initWithFrame:CGRectMake(flagButton.frame.origin.x + BUTTON_WIDTH, 0, BUTTON_WIDTH, BUTTON_HEIGHT)];
        [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [likeButton setBackgroundImage:[UIImage imageNamed:@"likeBlack.png"] forState:UIControlStateNormal];
        [likeButton setBackgroundImage:[UIImage imageNamed:@"likeRed.png"] forState:UIControlStateSelected];
        [likeButton setBackgroundImage:[UIImage imageNamed:@"likeRed.png"] forState:UIControlStateHighlighted];
        [self addSubview:likeButton];
        
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0, BUTTON_HEIGHT, self.frame.size.width, self.frame.size.height-BUTTON_HEIGHT)];
        textView.editable = NO;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        [self addSubview:textView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)updateWithNote:(Note *)aNote andIndex:(int)index
{
    note = aNote;
    
    usernameLabel.text = ([note.displayname length] > 0) ? note.displayname : note.username;
    deleteButton.tag = index;
    [flagButton setSelected:note.userFlagged];
    [self updateLikeButton];
    
    textView.text = note.title;
    CGRect frame = textView.frame;
    frame.size.height = textView.contentSize.height;
    textView.frame = frame;
}

#pragma mark Button Pressed

-(void)flagButtonPressed:(UIButton *) sender
{
    if([AppModel sharedAppModel].playerId == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Must Be Logged In" message:@"You must be logged in to flag notes." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log In", nil];
        [alert show];
    }
    else
    {
        if(note.userFlagged)
        {
            note.userFlagged = !flagButton.selected;
            [[AppServices sharedAppServices]unFlagNote:note.noteId];
            [flagButton setSelected:note.userFlagged];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mark Inappropriate" message:@"Are you sure you want to mark this content as inappropriate?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alert show];
        }
        
    }
}

-(void)likeButtonPressed:(UIButton *) sender
{
    if([AppModel sharedAppModel].playerId == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Must Be Logged In" message:@"You must be logged in to like notes." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log In", nil];
        [alert show];
    }
    else
    {
        note.userLiked = !likeButton.selected;
        if(note.userLiked)
        {
            [[AppServices sharedAppServices]likeNote:note.noteId];
            note.numRatings++;
        }
        else
        {
            [[AppServices sharedAppServices] unLikeNote:note.noteId];
            note.numRatings--;
        }
        [self updateLikeButton];
    }
}

-(void)updateLikeButton
{
    [likeButton setSelected:note.userLiked];
    [likeButton setTitle:[NSString stringWithFormat:@"%d",note.numRatings] forState:UIControlStateNormal];
    [likeButton setTitle:[NSString stringWithFormat:@"%d",note.numRatings] forState:UIControlStateSelected];
    [likeButton setTitle:[NSString stringWithFormat:@"%d",note.numRatings] forState:UIControlStateHighlighted];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"Must Be Logged In"] && buttonIndex != 0)
    {
        [delegate presentLogIn];
    }
    else if([alertView.title isEqualToString:@"Mark Inappropriate"] && buttonIndex != 0)
    {
        note.userFlagged = !flagButton.selected;
        [[AppServices sharedAppServices]flagNote:note.noteId];
        [flagButton setSelected:note.userFlagged];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank You" message:@"Thank you for your input. We will look into the matter further and remove inappropriate content." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
}

@end
