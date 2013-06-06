//
//  InnovListViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import "InnovListViewController.h"

#import "Note.h"
#import "NoteContent.h"

#import "TMQuiltView.h"
#import "TMPhotoQuiltViewCell.h"

#define NUM_COLUMNS 2

#define CELL_HEIGHT 160
#define CELL_WIDTH  160

#define CELL_X_MARGIN 5
#define CELL_Y_MARGIN 5

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
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteList:) name:@"NotesAvailableChanged" object:nil];
    }
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
        cell.photoView.dontUseImage  = YES;
    }
    
    Note *note = [notes objectAtIndex:indexPath.row];
    
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
#warning Landscape?
   // if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft
   //     || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
   //     return 3;
    
    return NUM_COLUMNS;
}

- (CGFloat)quiltView:(TMQuiltView *)aQuiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    //   return ((TMPhotoQuiltViewCell *)[self quiltView:quiltView cellAtIndexPath:indexPath]).photoView.frame.size.height / [self quiltViewNumberOfColumns:aQuiltView];
    
    return CELL_HEIGHT;
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate presentNote: [notes objectAtIndex:indexPath.row]];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [quiltView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end