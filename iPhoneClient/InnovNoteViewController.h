//
//  InnovNoteViewController.h
//  YOI
//
//  Created by Jacob James Hanshaw on 5/8/13.
//
//

#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "Note.h"
#import "InnovNoteEditorViewController.h"
#import "AsyncMediaTouchableImageView.h"
#import "ARISMoviePlayerViewController.h"

typedef enum {
	kInnovAudioPlayerNoAudio,
	kInnovAudioPlayerAudio,
	kInnovAudioPlayerPlaying
} InnovAudioViewerModeType;

@interface InnovNoteViewController : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, AsyncMediaTouchableImageViewDelegate, AsyncMediaImageViewDelegate> //, InnovNoteViewDelegate
{
    
    __weak IBOutlet AsyncMediaTouchableImageView *imageView;
    __weak IBOutlet UITextView *captionTextView;
    __weak IBOutlet UIButton *playButton;
    __weak IBOutlet UITableView *commentTableView;
    
    Note *note;
    UIBarButtonItem *editButton;
    //UIBarButtonItem *cancelButton;
    id __unsafe_unretained delegate;
    
    CGRect originalImageViewFrame;
    
	InnovAudioViewerModeType mode;
    BOOL shouldAutoPlay;
    ARISMoviePlayerViewController *ARISMoviePlayer;
    
}

@property (nonatomic)                    Note *note;
@property (nonatomic, unsafe_unretained) id delegate;

- (IBAction) playButtonPressed:(id)sender;
- (IBAction) expandButtonPressed:(id)sender;
- (IBAction) flagButtonPressed:(id)sender;
- (IBAction) commentButtonPressed:(id)sender;
- (IBAction) likeButtonPressed:(id)sender;


@end
