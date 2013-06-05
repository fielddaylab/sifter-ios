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

#define MAIN_IMAGE_HEIGHT 160
#define MAIN_IMAGE_WIDTH  160
/*
 #define ICON_WIDTH          76
 #define ICON_HEIGHT         90
 #define ICONS_PER_ROW       3
 #define ICONS_MARGIN        20
 #define TEXT_LABEL_HEIGHT   10
 #define TEXT_LABEL_PADDING  7
 */
static NSString * const CELL_ID = @"Cell";

@interface InnovListViewController () <TMQuiltViewDataSource, TMQuiltViewDelegate> //<UICollectionViewDataSource,UICollectionViewDelegate>//
{
    /*UIScrollView *questIconScrollView;
     UICollectionView *questIconCollectionView;
     UICollectionViewFlowLayout *questIconCollectionViewLayout;
     
     int itemsPerColumnWithoutScrolling;
     int initialHeight;
     
     BOOL supportsCollectionView; */
    
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
    
    /*
     if(NSClassFromString(@"UICollectionView"))
     {
     supportsCollectionView = YES;
     questIconCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
     questIconCollectionViewLayout.itemSize = CGSizeMake(ICON_WIDTH, ICON_HEIGHT);
     questIconCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
     questIconCollectionViewLayout.sectionInset = UIEdgeInsetsMake(ICONS_MARGIN, ICONS_MARGIN, 0, ICONS_MARGIN);
     questIconCollectionViewLayout.minimumLineSpacing = ICONS_MARGIN;
     questIconCollectionViewLayout.minimumInteritemSpacing = ICONS_MARGIN;
     
     questIconCollectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:questIconCollectionViewLayout];
     questIconCollectionView.dataSource = self;
     questIconCollectionView.delegate = self;
     questIconCollectionView.backgroundColor = [UIColor blackColor];
     [questIconCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:CELL_ID];
     [self.view addSubview:questIconCollectionView];
     }
     else
     {
     supportsCollectionView = NO;
     questIconScrollView=[[UIScrollView alloc] initWithFrame:self.view.frame];
     questIconScrollView.contentSize=CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
     questIconScrollView.backgroundColor = [UIColor blackColor];
     
     initialHeight = self.view.frame.size.height;
     itemsPerColumnWithoutScrolling = self.view.frame.size.height/ICON_HEIGHT + .5;
     itemsPerColumnWithoutScrolling--;
     
     [self.view addSubview:questIconScrollView];
     }
     */
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
    
    TMPhotoQuiltViewCell *cell;// = (TMPhotoQuiltViewCell *)[aQuiltView dequeueReusableCellWithReuseIdentifier:CELL_ID];
    if (!cell)
    {
        cell = [[TMPhotoQuiltViewCell alloc] initWithReuseIdentifier:CELL_ID];
        CGRect frame = cell.frame;
        frame.size.width = MAIN_IMAGE_WIDTH;
        frame.size.height = MAIN_IMAGE_HEIGHT;
        cell.frame = frame;

        frame.origin.x = 0;
        frame.origin.y = 0;
        cell.photoView = [[AsyncMediaImageView alloc] init];
        cell.photoView.frame = frame;
        cell.photoView.clipsToBounds = YES;
        cell.photoView.dontUseImage  = YES;
        cell.photoView.contentMode = UIViewContentModeScaleAspectFill;
        [cell addSubview:cell.photoView];
    }
    
    
    Note *note = [notes objectAtIndex:indexPath.row];
    
    for(NoteContent *noteContent in note.contents)
    {
        if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
        {
           [cell.photoView reset];
           [cell.photoView loadImageFromMedia:[noteContent getMedia]];

            break;
        }
    }
    
    NSString *titleWithoutUsername = [note.title substringToIndex: [note.title rangeOfString:@"#" options:NSBackwardsSearch].location];
    
    if([titleWithoutUsername isEqualToString:@""] || [titleWithoutUsername isEqualToString:@" "]) cell.titleLabel.hidden = YES;
    else {
        cell.titleLabel.hidden = NO;
        cell.titleLabel.text = titleWithoutUsername;
    }
    
    return cell;
}
#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView {
    
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft
        || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
        return 3;
    
    return 2;
    
}

- (CGFloat)quiltView:(TMQuiltView *)aQuiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    //   return ((TMPhotoQuiltViewCell *)[self quiltView:quiltView cellAtIndexPath:indexPath]).photoView.frame.size.height / [self quiltViewNumberOfColumns:aQuiltView];
#warning recomment in below
    
  //  return 320/[self quiltViewNumberOfColumns:aQuiltView];
    return MAIN_IMAGE_HEIGHT;
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate presentNote: [notes objectAtIndex:indexPath.row]];
}

/*
 -(void)refreshViewFromModel
 {
 
 NSSortDescriptor *sortDescriptor;
 sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortNum" ascending:YES];
 NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
 NSArray *sortedActiveQuests    = [[AppModel sharedAppModel].currentGame.questsModel.currentActiveQuests    sortedArrayUsingDescriptors:sortDescriptors];
 NSArray *sortedCompletedQuests = [[AppModel sharedAppModel].currentGame.questsModel.currentCompletedQuests sortedArrayUsingDescriptors:sortDescriptors];
 
 sortedQuests = [sortedActiveQuests arrayByAddingObjectsFromArray:sortedCompletedQuests];
 
 if(supportsCollectionView) [questIconCollectionView reloadData];
 else [self createIcons];
 }
 
 -(void)createIcons
 {
 for (UIView *view in [questIconScrollView subviews])
 [view removeFromSuperview];
 
 for(int i = 0; i < [sortedQuests count]; i++)
 {
 Quest *currentQuest = [sortedQuests objectAtIndex:i];
 int xMargin = truncf((questIconScrollView.frame.size.width - ICONSPERROW * ICONWIDTH)/(ICONSPERROW +1));
 int yMargin = truncf((initialHeight - itemsPerColumnWithoutScrolling * ICONHEIGHT)/(itemsPerColumnWithoutScrolling + 1));
 int row = (i/ICONSPERROW);
 int xOrigin = (i % ICONSPERROW) * (xMargin + ICONWIDTH) + xMargin;
 int yOrigin = row * (yMargin + ICONHEIGHT) + yMargin;
 
 UIImage *iconImage;
 if(currentQuest.iconMediaId != 0){
 Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId: currentQuest.iconMediaId];
 iconImage = [UIImage imageWithData:iconMedia.image];
 }
 else iconImage = [UIImage imageNamed:@"item.png"];
 IconQuestsButton *iconButton = [[IconQuestsButton alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, ICONWIDTH, ICONHEIGHT) andImage:iconImage andTitle:currentQuest.name];
 iconButton.tag = i;
 [iconButton addTarget:self action:@selector(questSelected:) forControlEvents:UIControlEventTouchUpInside];
 iconButton.imageView.layer.cornerRadius = 9.0;
 [questIconScrollView addSubview:iconButton];
 [iconButton setNeedsDisplay];
 }
 }
 
 - (void) questSelected: (id)sender
 {
 UIButton *button = (UIButton*)sender;
 
 Quest *questSelected = [sortedQuests objectAtIndex:button.tag];
 
 QuestDetailsViewController *questDetailsViewController =[[QuestDetailsViewController alloc] initWithQuest: questSelected];
 questDetailsViewController.navigationItem.title = questSelected.name;
 [[self navigationController] pushViewController:questDetailsViewController animated:YES];
 }
 
 #pragma mark CollectionView DataSource and Delegate Methods
 
 - (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
 {
 return 1;
 }
 
 - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
 {
 return [self.quests count];
 }
 
 - (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
 {
 UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
 
 for (UIView *view in [cell.contentView subviews])
 [view removeFromSuperview];
 
 int questNumber = indexPath.item;
 
 Quest *currentQuest = [sortedQuests objectAtIndex:questNumber];
 
 UIImage *iconImage;
 if(currentQuest.iconMediaId != 0)
 {
 Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId: currentQuest.iconMediaId];
 iconImage = [UIImage imageWithData:iconMedia.image];
 }
 else iconImage = [UIImage imageNamed:@"item.png"];
 UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height - TEXTLABELHEIGHT - (2*TEXTLABELPADDING))];
 [iconImageView setImage:iconImage];
 iconImageView.layer.cornerRadius = 11.0f;
 [cell.contentView addSubview:iconImageView];
 
 CGRect textFrame = CGRectMake(0, (cell.contentView.frame.size.height-TEXTLABELHEIGHT - TEXTLABELPADDING), cell.contentView.frame.size.width, TEXTLABELHEIGHT);
 UILabel *iconTitleLabel = [[UILabel alloc] initWithFrame:textFrame];
 iconTitleLabel.text = currentQuest.name;
 iconTitleLabel.textColor = [UIColor whiteColor];
 iconTitleLabel.backgroundColor = [UIColor clearColor];
 iconTitleLabel.textAlignment = UITextAlignmentCenter;
 iconTitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
 iconTitleLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
 [cell.contentView addSubview:iconTitleLabel];
 
 return cell;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
 {
 NSArray *activeQuests = [self.quests objectAtIndex:ACTIVE_SECTION];
 NSArray *completedQuests = [self.quests objectAtIndex:COMPLETED_SECTION];
 
 int questNumber = indexPath.item;
 
 Quest *questSelected;
 if(questNumber >= [activeQuests count])
 {
 questNumber -= [activeQuests count];
 questSelected = [completedQuests objectAtIndex:questNumber];
 }
 else questSelected = [activeQuests objectAtIndex:questNumber];
 QuestDetailsViewController *questDetailsViewController =[[QuestDetailsViewController alloc] initWithQuest: questSelected];
 questDetailsViewController.navigationItem.title = questSelected.name;
 [[self navigationController] pushViewController:questDetailsViewController animated:YES];
 }
 
 #pragma mark TableView Delegate and Datasource Methods
 
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)atableView {
 return [availableTags count];
 }
 
 - (NSInteger)tableView:(UITableView *)atableView numberOfRowsInSection:(NSInteger)section {
 return [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:section]).tagName] count];
 }
 
 // Customize the appearance of table view cells.
 - (UITableViewCell *)tableView:(UITableView *)atableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 #warning unimplemented
 
 // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
 // if(cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
 
 // cell.textLabel.text = @"ROW";
 
 //InnovTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
 //if(cell == nil) cell = [[InnovTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
 
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InnovTableViewCell"];
 if (cell == nil) {
 // Load the top-level objects from the custom cell XIB.
 NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"InnovTableViewCell" owner:self options:nil];
 // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
 
 //cell = [topLevelObjects objectAtIndex:0];
 }
 
 // ((InnovTableViewCell*)cell).note = [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:indexPath.section]).tagName] objectAtIndex:indexPath.row];
 //   [((InnovTableViewCell*)cell) updateCell];
 
 
 return cell;
 }
 
 -(NSString *)tableView:(UITableView *)atableView titleForHeaderInSection:(NSInteger)section{
 return ((Tag *)[availableTags objectAtIndex:section]).tagName;
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0,0, 320, 44)] autorelease];
 UILabel *label = [[[UILabel alloc] initWithFrame:headerView.frame] autorelease];
 label.textColor = [UIColor redColor];
 label.text = [NSString stringWithFormat:@"Section %i", section];
 
 [headerView addSubview:label];
 return headerView;
 }
 
 
 -(CGFloat)tableView:(UITableView *)atableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
 return 500;// [[UIScreen mainScreen] applicationFrame].size.height - self.navigationController.navigationBar.frame.size.height;
 #warning unimplemented
 }
 
 - (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 #warning unimplemented
 
 }
 */

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [quiltView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

@end