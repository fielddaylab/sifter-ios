//
//  InnovCommentViewController.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/1/13.
//
//

#import "InnovCommentViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "Note.h"
#import "Tag.h"
#import "Comment.h"
#import "AppModel.h"
#import "AppServices.h"
#import "InnovNoteModel.h"
#import "InnovCommentCell.h"
#import "DAKeyboardControl.h"
#import "LoginViewController.h"

#define DEFAULT_TEXT                @"Add a comment..."
#define DEFAULT_FONT                [UIFont fontWithName:@"Helvetica" size:14]
#define DEFAULT_TEXTVIEW_MARGIN     8
#define ADJUSTED_TEXTVIEW_MARGIN    0

#define COMMENT_BAR_HEIGHT          46
#define COMMENT_BAR_HEIGHT_MAX      80
#define COMMENT_BAR_X_MARGIN        10
#define COMMENT_BAR_Y_MARGIN        6
#define COMMENT_BAR_BUTTON_WIDTH    58

static NSString * const COMMENT_CELL_ID = @"CommentCell";

@interface InnovCommentViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    __weak IBOutlet UITableView *commentTableView;
    
    UIToolbar       *addCommentBar;
    UITextView      *addCommentTextView;
    UIBarButtonItem *addCommentButton;
}

@end

@implementation InnovCommentViewController

@synthesize note;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = @"Comments";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NoteModelUpdate:Notes" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    addCommentBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                self.view.bounds.size.height - COMMENT_BAR_HEIGHT,
                                                                self.view.bounds.size.width,
                                                                COMMENT_BAR_HEIGHT)];
    addCommentBar.barStyle = UIBarStyleBlackOpaque;
    addCommentBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:addCommentBar];
    
    addCommentTextView =      [[UITextView alloc] initWithFrame:CGRectMake(COMMENT_BAR_X_MARGIN,
                                                                           COMMENT_BAR_Y_MARGIN,
                                                                           addCommentBar.bounds.size.width - (2 * COMMENT_BAR_X_MARGIN)  - (COMMENT_BAR_BUTTON_WIDTH + COMMENT_BAR_X_MARGIN),
                                                                           COMMENT_BAR_HEIGHT-COMMENT_BAR_Y_MARGIN*2)];
    addCommentTextView.delegate            = self;
    addCommentTextView.layer.cornerRadius  = 9.0f;
    addCommentTextView.font                = DEFAULT_FONT;
    addCommentTextView.contentInset        = UIEdgeInsetsMake(-8,-4,-8,-4);
    addCommentTextView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [addCommentBar addSubview:addCommentTextView];
    
    addCommentButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(addCommentButtonPressed:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [addCommentBar setItems:[NSArray arrayWithObjects:flex, addCommentButton, nil]];
}
/*
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    addCommentTextView.text      = DEFAULT_TEXT;
    addCommentTextView.textColor = [UIColor lightGrayColor];
    [self adjustCommentBarToFitText];
 
    if([self.note.tags count] > 0)
        self.title = ((Tag *)[self.note.tags objectAtIndex:0]).tagName;
    else
        self.title = @"Note";
    
    self.view.keyboardTriggerOffset = addCommentBar.bounds.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */ /*
#warning check if necessary now that is loaded and released with view visibile
        if (self.isViewLoaded && self.view.window)
        {
            CGRect addCommentBarFrame = addCommentBar.frame;
            addCommentBarFrame.origin.y = keyboardFrameInView.origin.y - addCommentBarFrame.size.height;
            addCommentBar.frame = addCommentBarFrame;
            
            CGRect tableViewFrame = commentTableView.frame;
            tableViewFrame.size.height = addCommentBarFrame.origin.y;
            commentTableView.frame = tableViewFrame;
            
            [commentTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([commentTableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.view removeKeyboardControl];
}

#pragma mark Refresh

- (void)refreshViewFromModel
{
    self.note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.note.noteId];
    [self updateLikeButton];
    [flagButton setSelected:self.note.userFlagged];
    
    for(int i = 0; i < [self.note.contents count]; ++i)
    {
        NoteContent *noteContent = [self.note.contents objectAtIndex:i];
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
            [imageView loadImageFromMedia:[noteContent getMedia]];
        else if ([[noteContent getType] isEqualToString:kNoteContentTypeAudio]) {
            if (![[ARISMoviePlayer.moviePlayer.contentURL absoluteString] isEqualToString: [noteContent getMedia].url]) {
                [ARISMoviePlayer.moviePlayer setContentURL: [NSURL URLWithString:[noteContent getMedia].url]];
                [ARISMoviePlayer.moviePlayer prepareToPlay];
			}
            mode = kInnovAudioPlayerAudio;
            [self updateButtonsForCurrentMode];
        }
    }
    
    [noteTableView reloadData];
}

#pragma mark UITextView methods

- (void) textViewDidBeginEditing:(UITextView *)textView
{
    textView.textColor = [UIColor blackColor];
    if([textView.text isEqualToString:DEFAULT_TEXT]) textView.text = @"";
}

- (void) textViewDidChange:(UITextView *)textView
{
    [self adjustCommentBarToFitText];
    [commentTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([commentTableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void) adjustCommentBarToFitText
{
    CGSize size = CGSizeMake(addCommentTextView.frame.size.width - (2 * ADJUSTED_TEXTVIEW_MARGIN), COMMENT_BAR_HEIGHT_MAX - (2 * COMMENT_BAR_Y_MARGIN));
    CGFloat newHeight = ([addCommentTextView.text sizeWithFont:addCommentTextView.font constrainedToSize:size].height + (2 * ADJUSTED_TEXTVIEW_MARGIN)) + (2 * COMMENT_BAR_Y_MARGIN);
    CGFloat oldHeight = addCommentBar.frame.size.height;
    
    CGRect frame = addCommentBar.frame;
    frame.size.height = MAX(newHeight, COMMENT_BAR_HEIGHT);
    frame.origin.y   += oldHeight-frame.size.height;
    
    addCommentBar.frame = frame;
    
    CGRect tableViewFrame = commentTableView.frame;
    tableViewFrame.size.height = addCommentBar.frame.origin.y;
    commentTableView.frame = tableViewFrame;
    
    self.view.keyboardTriggerOffset = addCommentBar.bounds.size.height;
}

- (void) addCommentButtonPressed:(id)sender
{
    [addCommentTextView resignFirstResponder];
    
    if([AppModel sharedAppModel].playerId == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Must Be Logged In" message:@"You must be logged in to comment on notes." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log In", nil];
        [alert show];
    }
    else if([addCommentTextView.text length] > 0 && ![addCommentTextView.text isEqualToString:DEFAULT_TEXT])
    {
        Note *commentNote = [[Note alloc] init];
        commentNote.noteId = [[AppServices sharedAppServices] addCommentToNoteWithId:self.note.noteId andTitle:@""];
        
        commentNote.title = [NSString stringWithFormat:@"%@ -%@", addCommentTextView.text, [AppModel sharedAppModel].userName];
        commentNote.parentNoteId = self.note.noteId;
        commentNote.creatorId = [AppModel sharedAppModel].playerId;
        commentNote.username = [AppModel sharedAppModel].userName;
#warning probably unnecessary to do this second call
        [[AppServices sharedAppServices]updateCommentWithId:commentNote.noteId andTitle:commentNote.title andRefresh:YES];
        
        [self.note.comments insertObject:commentNote atIndex:0];
        [[InnovNoteModel sharedNoteModel] updateNote:note];
    }
    
    addCommentTextView.text = DEFAULT_TEXT;
    addCommentTextView.textColor = [UIColor lightGrayColor];
    
    [self adjustCommentBarToFitText];
    
    [commentTableView reloadData];
    [commentTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([commentTableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"Must Be Logged In"] && buttonIndex != 0)
    {
        LoginViewController *logInVC = [[LoginViewController alloc] init];
        [self.navigationController pushViewController:logInVC animated:YES];
    }
    else if(buttonIndex != 0)
    {
#warning must specifiy comment to flag somehow
#warning disable interactions with table until response and then enable after
        self.note.userFlagged = !flagButton.selected;
        [[AppServices sharedAppServices]flagNote:self.note.noteId];
        [flagButton setSelected:self.note.userFlagged];
    }
}

#pragma mark Table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([note.comments count] > DEFAULT_MAX_VISIBLE_COMMENTS && !expanded)
        return DEFAULT_MAX_VISIBLE_COMMENTS + 1;
    else
        return [note.comments count] + 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0)
    {
        CGSize size = CGSizeMake(captionTextView.frame.size.width - (2 * ADJUSTED_TEXTVIEW_MARGIN), CGFLOAT_MAX);
        NSString *text = note.title;
        CGFloat captionTextViewHeight = [text sizeWithFont:captionTextView.font constrainedToSize:size].height + (2 * ADJUSTED_TEXTVIEW_MARGIN);
        if(!([text length] > 0))
            captionTextViewHeight = -4;
#warning MAGIC NUMBER
        return imageView.frame.size.height + BUTTON_HEIGHT + captionTextViewHeight + 4;
    }
    else
    {
        CGSize size = CGSizeMake(self.view.frame.size.width - (2 * DEFAULT_TEXTVIEW_MARGIN), CGFLOAT_MAX);
        
        NSString *text;
        if(expanded || indexPath.row < EXPAND_INDEX || [note.comments count] <= DEFAULT_MAX_VISIBLE_COMMENTS)
            text      = ((Note *)[note.comments objectAtIndex:[note.comments count]-indexPath.row]).title;
        else if(!expanded && indexPath.row == EXPAND_INDEX)
            text      = EXPAND_TEXT;
        else
            text      = ((Note *)[note.comments objectAtIndex:(DEFAULT_MAX_VISIBLE_COMMENTS-indexPath.row)]).title;
        
        return [text sizeWithFont:DEFAULT_FONT constrainedToSize:size].height + (2 * DEFAULT_TEXTVIEW_MARGIN);
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:NOTE_CELL_ID];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NOTE_CELL_ID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell addSubview:imageView];
            [cell addSubview:usernameLabel];
            [cell addSubview:flagButton];
            [cell addSubview:playButton];
            [cell addSubview:likeButton];
            [cell addSubview:shareButton];
            [cell addSubview:captionTextView];
        }
        

        return cell;
    }
    else
    {
        InnovCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:COMMENT_CELL_ID];
        if(!cell)
        {
            cell = [[InnovCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:COMMENT_CELL_ID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.font = DEFAULT_FONT;
        }
        
        if(!expanded && indexPath.row == EXPAND_INDEX && [note.comments count] > DEFAULT_MAX_VISIBLE_COMMENTS)
        {
            cell.textView.userInteractionEnabled = NO;
            cell.textView.textAlignment = NSTextAlignmentCenter;
            cell.textView.text          = EXPAND_TEXT;
        }
        else
        {
            cell.textView.userInteractionEnabled = YES;
            cell.textView.textAlignment = NSTextAlignmentLeft;
            if(expanded || indexPath.row < EXPAND_INDEX || [note.comments count] <= DEFAULT_MAX_VISIBLE_COMMENTS)
                cell.textView.text      = ((Note *)[note.comments objectAtIndex:[note.comments count]-indexPath.row]).title;
            else
                cell.textView.text      = ((Note *)[note.comments objectAtIndex:(DEFAULT_MAX_VISIBLE_COMMENTS-indexPath.row)]).title;
            
            CGRect frame = cell.textView.frame;
            frame.size.height = cell.textView.contentSize.height;
            cell.textView.frame = frame;
        }
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [addCommentTextView resignFirstResponder];
    
    if(![addCommentTextView.text length])
    {
        addCommentTextView.text = DEFAULT_TEXT;
        addCommentTextView.textColor = [UIColor lightGrayColor];
        [self adjustCommentBarToFitText];
    }
    
    if(!expanded && indexPath.row == 3)
    {
        expanded = YES;
        [tableView reloadData];
    }
}
*/
#pragma mark Remove Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    commentTableView = nil;
    [super viewDidUnload];
}

@end