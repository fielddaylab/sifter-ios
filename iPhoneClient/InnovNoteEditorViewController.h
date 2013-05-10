//
//  InnovNoteEditorViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "Note.h"
#import "AsyncMediaTouchableImageView.h"
#import "ARISMoviePlayerViewController.h"
/*
@protocol InnovNoteViewDelegate

@required
- (void) shouldAlsoExit:(BOOL) shouldExit;
@end
*/
typedef enum {
	kInnovAudioRecorderNoAudio,
	kInnovAudioRecorderRecording,
	kInnovAudioRecorderAudio,
	kInnovAudioRecorderPlaying
} InnovAudioRecorderModeType;

@interface InnovNoteEditorViewController : UIViewController <AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, AsyncMediaTouchableImageViewDelegate, AsyncMediaImageViewDelegate> {
    
    __weak IBOutlet AsyncMediaTouchableImageView *imageView;
    __weak IBOutlet UITextView *captionTextView;
    __weak IBOutlet UIButton *recordButton;
    __weak IBOutlet UIButton *deleteAudioButton;
    __weak IBOutlet UITableView *tagTableView;
    
    UIBarButtonItem *cancelButton;

    Note *note;
    id __unsafe_unretained delegate;
    BOOL isEditing;
    
    BOOL newNote;
    int originalTagId;
    NSString  *originalTagName;
    int selectedIndex;
    NSString  *newTagName;
    BOOL cancelled;
    BOOL hasAudioToUpload;
    NSMutableArray *tagList;
    
    BOOL shouldAutoplay;
    ARISMoviePlayerViewController *ARISMoviePlayer;
    
    //AudioMeter *meter;
	AVAudioRecorder *soundRecorder;
	AVAudioPlayer *soundPlayer;
	NSURL *soundFileURL;
	InnovAudioRecorderModeType mode;
	NSTimer *recordLengthCutoffTimer;
    
}

@property (nonatomic)                    Note *note;
@property (nonatomic, unsafe_unretained) id delegate;               

- (IBAction)recordButtonPressed:(id)sender;
- (IBAction)deleteAudioButtonPressed:(id)sender;

@end
