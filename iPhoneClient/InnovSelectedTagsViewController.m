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
#import "Logger.h"

#define IMAGEHEIGHT 35
#define IMAGEWIDTH 35
#define SPACING 20
#define ANIMATION_DURATION 0.15


@interface InnovSelectedTagsViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    __weak IBOutlet UISegmentedControl *contentSelectorSegCntrl;
    __weak IBOutlet UITableView *tagTableView;
    
    BOOL hiding;
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
    
    selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    [[InnovNoteModel sharedNoteModel] setSelectedContent:selectedContent];
    
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
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:ANIMATION_DURATION];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [self.view.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void) hide
{
    if(!self.view.hidden && !hiding)
    {
        hiding = YES;
        
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
        [scale setToValue:[NSNumber numberWithFloat:0.0f]];
        [scale setDuration:ANIMATION_DURATION];
        [scale setRemovedOnCompletion:NO];
        [scale setFillMode:kCAFillModeForwards];
        scale.delegate = self;
        [self.view.layer addAnimation:scale forKey:@"transform.scaleDown"];
    }
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag){
        if (theAnimation == [[self.view layer] animationForKey:@"transform.scaleUp"] && !hiding)
            self.view.userInteractionEnabled = YES;
        else if(theAnimation == [[self.view layer] animationForKey:@"transform.scaleDown"] && hiding)
        {
            self.view.hidden = YES;
            [self willMoveToParentViewController:nil];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
    }
}

#pragma mark UISegmentedController delegate

- (IBAction)contentSelectorChangedValue:(UISegmentedControl *)sender
{
    selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    [[InnovNoteModel sharedNoteModel] setSelectedContent:selectedContent];
}

#pragma mark TableView DataSource and Delegate Methods

-(void)updateTags
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        CGSize textSize = [((Tag *)[tags objectAtIndex:indexPath.row]).tagName
                           sizeWithFont:[UIFont boldSystemFontOfSize:16]
                           constrainedToSize:CGSizeMake(cell.frame.size.width - IMAGEWIDTH - 2 * SPACING, cell.frame.size.height)
                           lineBreakMode:UILineBreakModeTailTruncation];
        cell.textLabel.frame = CGRectMake(0,0,textSize.width, textSize.height);
        [cell.textLabel setNumberOfLines:1];
        [cell.textLabel setLineBreakMode:UILineBreakModeTailTruncation];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [cell.textLabel setText:((Tag *)[tags objectAtIndex:indexPath.row]).tagName];
    
    
    cell.imageView.frame = CGRectMake( cell.textLabel.frame.origin.x + cell.textLabel.frame.size.width + SPACING,
                                      (cell.frame.size.height - IMAGEHEIGHT)/2,
                                      IMAGEWIDTH,
                                      IMAGEHEIGHT);
#warning comment back in
    // cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"tag%d.png", ((Tag *)[tagList  objectAtIndex:indexPath.row]).tagId]];
    
    BOOL match = NO;
    for(int i = 0; i < [selectedTags count]; ++i)
        if(((Tag *)[tags objectAtIndex:indexPath.row]).tagId == ((Tag *)[selectedTags objectAtIndex:i]).tagId) match = YES;
    
    if(match) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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