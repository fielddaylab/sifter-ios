//
//  InnovSelectedTagsViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/3/13.
//
//

#import "InnovSelectedTagsViewController.h"

#import "AppModel.h"
#import "Tag.h"

#import <QuartzCore/QuartzCore.h>

#define IMAGEHEIGHT 35
#define IMAGEWIDTH 35
#define SPACING 20


@interface InnovSelectedTagsViewController ()

@end

@implementation InnovSelectedTagsViewController

@synthesize selectedContent, selectedTagList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCategories)    name:@"NewTagListReady"  object:nil];
        
        self.view.hidden = YES;
        
        tagList = [[NSMutableArray alloc] initWithCapacity:10];
        selectedTagList = [[NSMutableArray alloc] initWithCapacity:10];
        selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    
    self.view.layer.anchorPoint = CGPointMake(0, 1);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:0.0f]];
    [scale setToValue:[NSNumber numberWithFloat:1.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [self.view.layer addAnimation:scale forKey:@"transform.scaleUp"];
}

- (void) hide
{
    hiding = YES;
    
    self.view.layer.anchorPoint = CGPointMake(0, 1);
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:[NSNumber numberWithFloat:1.0f]];
    [scale setToValue:[NSNumber numberWithFloat:0.0f]];
    [scale setDuration:0.8f];
    [scale setRemovedOnCompletion:NO];
    [scale setFillMode:kCAFillModeForwards];
    scale.delegate = self;
    [self.view.layer addAnimation:scale forKey:@"transform.scaleDown"];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(flag){
        if (theAnimation == [[self.view layer] animationForKey:@"transform.scaleUp"] && !hiding)
            self.view.userInteractionEnabled = YES;
        else if(theAnimation == [[self.view layer] animationForKey:@"transform.scaleDown"] && hiding)
            self.view.hidden = YES;
    }
}

#pragma mark UISegmentedController delegate

- (IBAction)contentSelectorChangedValue:(UISegmentedControl *)sender {
    selectedContent = [contentSelectorSegCntrl selectedSegmentIndex];
    [delegate didUpdateContentSelector];
}

#pragma mark TableView DataSource and Delegate Methods

-(void)refreshCategories
{
    [tagList removeAllObjects];
    [selectedTagList removeAllObjects];
    for(int i = 0; i < [[AppModel sharedAppModel].gameTagList count]; ++i)
    {
        [tagList addObject:[[AppModel sharedAppModel].gameTagList objectAtIndex:i]];
    }
    if([selectedTagList count] == 0) [selectedTagList addObject:[tagList objectAtIndex:0]];
    
    [tagTableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tagList count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        CGSize textSize = [((Tag *)[tagList objectAtIndex:indexPath.row]).tagName
                           sizeWithFont:[UIFont boldSystemFontOfSize:16]
                           constrainedToSize:CGSizeMake(cell.frame.size.width - IMAGEWIDTH - 2 * SPACING, cell.frame.size.height)
                           lineBreakMode:UILineBreakModeTailTruncation];
        cell.textLabel.frame = CGRectMake(0,0,textSize.width, textSize.height);
        [cell.textLabel setNumberOfLines:1];
        [cell.textLabel setLineBreakMode:UILineBreakModeTailTruncation];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [cell.textLabel setText:((Tag *)[tagList objectAtIndex:indexPath.row]).tagName];
    
    
    cell.imageView.frame = CGRectMake( cell.textLabel.frame.origin.x + cell.textLabel.frame.size.width + SPACING,
                                      (cell.frame.size.height - IMAGEHEIGHT)/2,
                                      IMAGEWIDTH,
                                      IMAGEHEIGHT);
#warning comment back in
    // cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"tag%d.png", ((Tag *)[tagList  objectAtIndex:indexPath.row]).tagId]];
    
    BOOL match = NO;
    for(int i = 0; i < [selectedTagList count]; ++i)
        if(((Tag *)[tagList objectAtIndex:indexPath.row]).tagId == ((Tag *)[selectedTagList objectAtIndex:i]).tagId) match = YES;
    
    if(match) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [selectedTagList removeObject:((Tag *)[tagList objectAtIndex:indexPath.row])];
    }
    else
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [selectedTagList addObject:((Tag *)[tagList objectAtIndex:indexPath.row])];
    }
    
    [delegate didUpdateSelectedTagList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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