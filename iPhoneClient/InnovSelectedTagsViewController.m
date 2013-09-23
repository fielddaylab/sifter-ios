//
//  InnovSelectedTagsViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import "InnovSelectedTagsViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "Tag.h"
#import "InnovTagCell.h"
#import "Logger.h"

#define ANIMATION_DURATION 0.15

@interface InnovSelectedTagsViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    __weak IBOutlet UISegmentedControl *contentSelectorSegCntrl;
    __weak IBOutlet UITableView *tagTableView;
    
    BOOL hiding;
    BOOL selectedTagsChanged;
    CGSize originalSize;
    CGSize hiddenSize;
    NSArray *tags;
    NSArray *selectedTags;
    
    ContentSelector selectedContent;
}

@end

@implementation InnovSelectedTagsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTags) name:@"NoteModelUpdate:Tags"          object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTags) name:@"NoteModelUpdate:SelectedTags"  object:nil];
        
        self.view.hidden = YES;
        
        tags =         [[NSArray alloc] init];
        selectedTags = [[NSArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    originalSize = self.view.frame.size;
    hiddenSize   = CGSizeMake(originalSize.width, 0);
    
    CGRect hiddenFrame = self.view.frame;
    hiddenFrame.size = hiddenSize;
    self.view.frame = hiddenFrame;
    
    [self updateTags];
}

# pragma  mark Display Methods

- (void) toggleDisplay
{
    if(self.view.hidden || hiding) [self show];
    else [self hide];
}

- (void) show
{
    hiding = NO;
    self.view.hidden = NO;
    self.view.userInteractionEnabled = NO;
    
    CGRect shownFrame = self.view.frame;
    shownFrame.size = originalSize;
    shownFrame.origin.y -= originalSize.height;
    
    __weak UIViewController *weakSelf = self;
    [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{ weakSelf.view.frame = shownFrame;}
                     completion:^(BOOL finished) { weakSelf.view.userInteractionEnabled = YES;}];
}

- (void) hide
{
    if(!self.view.hidden && !hiding)
    {
        hiding = YES;
        
        CGRect hiddenFrame = self.view.frame;
        hiddenFrame.size = hiddenSize;
        hiddenFrame.origin.y += originalSize.height;
        
        __weak UIViewController *weakSelf = self;
        [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{ weakSelf.view.frame = hiddenFrame;}
                         completion:^(BOOL finished) {
                             weakSelf.view.hidden = YES;
                             [weakSelf willMoveToParentViewController:nil];
                             [weakSelf.view removeFromSuperview];
                             [weakSelf removeFromParentViewController];
                             if(selectedTagsChanged)
                             {
                                 selectedTagsChanged = NO;
                                 [[InnovNoteModel sharedNoteModel] fetchMoreNotes];
                             }
                         }];
    }
}

#pragma mark UISegmentedController delegate

- (IBAction)contentSelectorChangedValue:(UISegmentedControl *)sender
{
    selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    [[InnovNoteModel sharedNoteModel] setSelectedContent:selectedContent];
    [tagTableView reloadData];
}

- (void)updateSelectedContent:(ContentSelector) selector
{
    contentSelectorSegCntrl.selectedSegmentIndex = selector;
    selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    [[InnovNoteModel sharedNoteModel] setSelectedContent:selectedContent];
    [tagTableView reloadData];
}

#pragma mark TableView DataSource and Delegate Methods

- (void)updateTags
{
    tags = [InnovNoteModel sharedNoteModel].allTags;
    selectedTags = [InnovNoteModel sharedNoteModel].selectedTags;
    [tagTableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tags count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    InnovTagCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[InnovTagCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell.tagLabel setNumberOfLines:1];
        [cell.tagLabel setLineBreakMode:UILineBreakModeTailTruncation];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [cell.tagLabel setText:((Tag *)[tags objectAtIndex:indexPath.row]).tagName];
    
    int mediaId = ((Tag *)[tags  objectAtIndex:indexPath.row]).mediaId;
    if(mediaId != 0)
        [cell.mediaImageView loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:mediaId]];
    else
        [cell.mediaImageView setImage:[UIImage imageNamed:@"noteicon.png"]];
    
    BOOL match = NO;
    for(int i = 0; i < [selectedTags count]; ++i)
        if(((Tag *)[tags objectAtIndex:indexPath.row]).tagId == ((Tag *)[selectedTags objectAtIndex:i]).tagId) match = YES;
    
    if(match) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    if(selectedContent == kMine)
    {
        cell.tagLabel.alpha       = 0.439216f;
        cell.mediaImageView.alpha = 0.439216f;
        cell.userInteractionEnabled = NO;
    }
    else
    {
        cell.tagLabel.alpha       = 1.0f;
        cell.mediaImageView.alpha = 1.0f;
        cell.userInteractionEnabled = YES;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedTagsChanged = YES;
    if([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [[InnovNoteModel sharedNoteModel] removeTag:((Tag *)[tags objectAtIndex:indexPath.row])];
    }
    else
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [[InnovNoteModel sharedNoteModel] addTag:((Tag *)[tags objectAtIndex:indexPath.row])];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    tagTableView = nil;
    contentSelectorSegCntrl = nil;
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end