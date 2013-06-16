//
//  InnovNoteEditorViewController.h
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

@protocol InnovNoteEditorViewDelegate
@optional
- (void) prepareToDisplayNote: (Note *) noteToAdd;
@end

typedef enum {
	kInnovAudioRecorderNoAudio,
	kInnovAudioRecorderRecording,
	kInnovAudioRecorderAudio,
	kInnovAudioRecorderPlaying
} InnovAudioRecorderModeType;

@class Note;

@interface InnovNoteEditorViewController : UIViewController

@property (nonatomic)                   Note *note;
@property (nonatomic, weak)             id<InnovNoteEditorViewDelegate> delegate;

-(void)refreshViewFromModel;

@end
