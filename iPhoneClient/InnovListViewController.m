//
//  InnovListViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import "InnovListViewController.h"
#import "InnovNoteModel.h"
#import "GlobalDefines.h"

#import "Note.h"
#import "Tag.h"
#import "NoteContent.h"

#import "TMQuiltView.h"
#import "TMPhotoQuiltViewCell.h"
#import "AsyncMediaImageView.h"
#import "CustomRefreshControl.h"
#import "UIColor+SifterColors.h"

#define NUM_COLUMNS 2

#define CELL_HEIGHT 160
#define CELL_WIDTH  160

#define CELL_X_MARGIN 3
#define CELL_Y_MARGIN 3

#define iOS7_CHANGE_ANIMATION_DURATION 0.001
#define ANIMATION_TIME     0.5

static NSString * const CELL_ID = @"Cell";

@interface InnovListViewController () <TMQuiltViewDataSource, TMQuiltViewDelegate, RefreshDelegate>
{
    TMQuiltView *quiltView;
    CustomRefreshControl *refreshControl;
    NSArray *notes;
    
    BOOL ignoreInitialContentOffsetScroll;
    BOOL currentlyWaitingForMoreNotes;
}

@end

@implementation InnovListViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNoteList:) name:@"NotesAvailableChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotes)    name:@"NoteModelUpdate:Notes" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ignoreInitialContentOffsetScroll = YES;
    
    CGRect quiltViewFrame = self.view.frame;
    quiltViewFrame.origin.x = 0;
    quiltViewFrame.origin.y = 0;
    quiltView = [[TMQuiltView alloc] initWithFrame:quiltViewFrame];
    quiltView.bounces = YES;
    quiltView.delegate = self;
    quiltView.dataSource = self;
    quiltView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:quiltView];
    quiltView.backgroundColor = [UIColor SifterColorWhite];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    refreshControl = [[CustomRefreshControl alloc] init];
    refreshControl.hidden = YES;
    refreshControl.tintColor = [UIColor SifterColorRed];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [quiltView addSubview:refreshControl];
    
    [self fixContentInset];
    
    [quiltView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    {
        __weak id weakSelfForBlock = self;
        [UIView animateWithDuration:iOS7_CHANGE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationCurveEaseInOut animations:^
         {  [weakSelfForBlock fixContentInset]; } completion: nil];
    }
}

- (void)fixContentInset
{
    float statusBarHeight = ([UIApplication sharedApplication].statusBarFrame.size.height == 0) ? STATUS_BAR_HEIGHT : [UIApplication sharedApplication].statusBarFrame.size.height;
    float navBarHeight = (self.navigationController.navigationBar.frame.size.height == 0) ? NAV_BAR_HEIGHT : self.navigationController.navigationBar.frame.size.height;
    if(quiltView.contentOffset.y <= 0)
        quiltView.contentOffset = CGPointMake(0.0, -(statusBarHeight + navBarHeight));
    quiltView.contentInset = UIEdgeInsetsMake(statusBarHeight + navBarHeight, 0.0,CELL_HEIGHT/2, 0.0);
    quiltView.scrollIndicatorInsets = quiltView.contentInset;
}

- (void)refresh:(UIRefreshControl *)refreshControl
{
    [[InnovNoteModel sharedNoteModel] refreshCurrentNotesWithDelegate:self];
}

- (void) refreshCompleted
{
    [refreshControl endRefreshing];
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
        index = 0;
        [mutableNotes insertObject:note atIndex:index];
        notes = [mutableNotes copy];
        [quiltView reloadData];
    }
    
    int row = index/NUM_COLUMNS;
    float topOfNewCell = row * CELL_HEIGHT;
    float offsetToCenter = quiltView.frame.size.height/2 - CELL_HEIGHT/2;
    float desiredLocation = topOfNewCell;
    if(offsetToCenter < topOfNewCell)
        desiredLocation += offsetToCenter;
    if((quiltView.contentSize.height > quiltView.frame.size.height) && desiredLocation >= quiltView.contentSize.height - quiltView.frame.size.height)
        desiredLocation = quiltView.contentSize.height - quiltView.frame.size.height;
    
    [UIView beginAnimations:@"animationInNote" context:NULL];
    [UIView setAnimationDuration:ANIMATION_TIME];
    quiltView.contentOffset = CGPointMake(0, desiredLocation);
    [UIView commitAnimations];
}

- (void) updateNoteList: (NSNotification *) notification
{
    currentlyWaitingForMoreNotes = NO;
    notes = (NSArray *)[notification.userInfo objectForKey:@"availableNotes"];
    [quiltView reloadData];
}

- (void) refreshNotes
{
    currentlyWaitingForMoreNotes = NO;
    [quiltView reloadData];
}

#pragma mark - TMQuiltViewDataSource

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)quiltView
{
    return [notes count];
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)aQuiltView cellAtIndexPath:(NSIndexPath *)indexPath
{
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
        cell.categoryIconView.frame = CGRectMake(cell.xMargin+cell.photoView.frame.size.width-ICON_WIDTH, cell.yMargin, ICON_WIDTH, ICON_HEIGHT);
        cell.backgroundColor = [UIColor SifterColorWhite];
    }
    
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:((Note *)[notes objectAtIndex:indexPath.row]).noteId];
    [cell.photoView reset];
    [cell.photoView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId]];
    
    if([note.tags count] > 0)
    {
        int mediaId = ((Tag *)[note.tags  objectAtIndex:0]).mediaId;
        if(mediaId != 0)
            [cell.categoryIconView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:mediaId]];
        else
            [cell.categoryIconView setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"noteicon" ofType:@"png"]]];
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

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    if(!ignoreInitialContentOffsetScroll)
    {
        float yOffset            = aScrollView.contentOffset.y;
        float scrollViewHeight   = aScrollView.bounds.size.height;
        float totalContentHeight = aScrollView.contentSize.height;
        float bottomInset        = aScrollView.contentInset.bottom;
        
        refreshControl.hidden = NO;
        
        if((yOffset+scrollViewHeight+bottomInset) >= (totalContentHeight - 10 * CELL_HEIGHT) && !currentlyWaitingForMoreNotes)
        {
            currentlyWaitingForMoreNotes = YES;
            [[InnovNoteModel sharedNoteModel] fetchMoreNotes];
        }
    }
    else
        ignoreInitialContentOffsetScroll = NO;
}

- (void) hideKeyboard: (UIGestureRecognizer *) gesture
{
    [self touchesBegan:nil withEvent:nil];
    [[self.navigationController.viewControllers objectAtIndex:0] touchesBegan:nil withEvent:nil];
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