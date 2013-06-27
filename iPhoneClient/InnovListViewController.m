//
//  InnovListViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import "InnovListViewController.h"
#import "InnovNoteModel.h"

#import "Note.h"
#import "NoteContent.h"

#import "TMQuiltView.h"
#import "TMPhotoQuiltViewCell.h"
#import "AsyncMediaImageView.h"

#define NUM_COLUMNS 2

#define CELL_HEIGHT 160
#define CELL_WIDTH  160

#define CELL_X_MARGIN 5
#define CELL_Y_MARGIN 5

#define ANIMATION_TIME     0.5

static NSString * const CELL_ID = @"Cell";

@interface InnovListViewController () <TMQuiltViewDataSource, TMQuiltViewDelegate>
{
    TMQuiltView *quiltView;
    
    NSArray *notes;
}

@end

@implementation InnovListViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteList:) name:@"NotesAvailableChanged" object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#warning doesn't handle touches began

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect quiltViewFrame = self.view.frame;
    quiltViewFrame.origin.x = 0;
    quiltViewFrame.origin.y = 0;
    quiltView = [[TMQuiltView alloc] initWithFrame:quiltViewFrame];
    quiltView.bounces = NO;
    quiltView.delegate = self;
    quiltView.dataSource = self;
    quiltView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:quiltView];
    
    [quiltView reloadData];
}

- (void) animateInNote:(Note *) newNote
{
    NSMutableArray *mutableNotes = [NSMutableArray arrayWithArray:notes];
    int index = -1;
    Note *note;
    
     //Use if the note won't always be the last note
    for(int i = 0; i < [mutableNotes count]; ++i)
    {
        note = [mutableNotes objectAtIndex:i];
        if(note.noteId == newNote.noteId)
        {
            index = i;
            break;
        }
    }
    if(index == -1)
    {
        index = [mutableNotes count];
        [mutableNotes addObject:note];
        notes = [mutableNotes copy];
        [quiltView reloadData];
    }
    
    int row = index/NUM_COLUMNS;
    float topOfNewCell = row * CELL_HEIGHT;
    float offsetToCenter = quiltView.frame.size.height/2 - CELL_HEIGHT/2;
    float desiredLocation = topOfNewCell;
    if(offsetToCenter < topOfNewCell)
        desiredLocation += offsetToCenter;
    if(desiredLocation >= quiltView.contentSize.height - quiltView.frame.size.height)
        desiredLocation = quiltView.contentSize.height - quiltView.frame.size.height;

    [UIView beginAnimations:@"animationInNote" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    quiltView.contentOffset = CGPointMake(0, desiredLocation);
    [UIView commitAnimations];
    
}

- (void) updateNoteList: (NSNotification *) notification
{
    notes = (NSArray *)[notification.userInfo objectForKey:@"availableNotes"];
    [quiltView reloadData];
}

#pragma mark - TMQuiltViewDataSource

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)quiltView
{
    return [notes count];
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)aQuiltView cellAtIndexPath:(NSIndexPath *)indexPath {
    
    TMPhotoQuiltViewCell *cell = (TMPhotoQuiltViewCell *)[aQuiltView dequeueReusableCellWithReuseIdentifier:CELL_ID];
    if (!cell)
    {
        cell = [[TMPhotoQuiltViewCell alloc] initWithReuseIdentifier:CELL_ID];
        CGRect frame = cell.frame;
        frame.size.width = CELL_WIDTH;
        frame.size.height = CELL_HEIGHT;
        cell.frame = frame;
        
        frame.origin.x = 0;
        frame.origin.y = 0;
        cell.xMargin = CELL_X_MARGIN;
        cell.yMargin = CELL_Y_MARGIN;
        cell.photoView.frame = frame;
        cell.photoView.dontUseImage = YES;
    }
    
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:((Note *)[notes objectAtIndex:indexPath.row]).noteId];
    for(NoteContent *noteContent in note.contents)
    {
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
        {
            [cell.photoView reset];
            [cell.photoView loadImageFromMedia:[noteContent getMedia]];
            [cell.categoryIconView setImage:[UIImage imageNamed:@"newBanner.png"]];
            break;
        }
    }
    
    return cell;
}
#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView
{
    return NUM_COLUMNS;
}

- (CGFloat)quiltView:(TMQuiltView *)aQuiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath
{    
    return CELL_HEIGHT;
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate presentNote: [notes objectAtIndex:indexPath.row]];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    float yOffset            = aScrollView.contentOffset.y;
    float scrollViewHeight   = aScrollView.bounds.size.height;
    float totalContentHeight = aScrollView.contentSize.height;
    float bottomInset        = aScrollView.contentInset.bottom;

    if(((yOffset+scrollViewHeight+bottomInset) >= (totalContentHeight - 10 * CELL_HEIGHT)) && [notes count] > NOTES_PER_FETCH)
        [[InnovNoteModel sharedNoteModel] fetchMoreNotes];
}
/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //possible adjust num rows
    [quiltView reloadData];
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end