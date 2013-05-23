//
//  InnovListViewController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/23/13.
//
//

#import "InnovListViewController.h"

//#import "TMQuiltView.h"
//#import "TMPhotoQuiltViewCell.h"

#define ICON_WIDTH          76
#define ICON_HEIGHT         90
#define ICONS_PER_ROW       3
#define ICONS_MARGIN        20
#define TEXT_LABEL_HEIGHT   10
#define TEXT_LABEL_PADDING  7

static NSString * const CELL_ID = @"Cell";

@interface InnovListViewController () <UICollectionViewDataSource,UICollectionViewDelegate>//<TMQuiltViewDataSource, TMQuiltViewDelegate>
{
    UIScrollView *questIconScrollView;
    UICollectionView *questIconCollectionView;
    UICollectionViewFlowLayout *questIconCollectionViewLayout;
    
    //    TMQuiltView *quiltView;
    //NSMutableArray *images;
    //NSMutableArray *text;
    
    int itemsPerColumnWithoutScrolling;
    int initialHeight;
    
    BOOL supportsCollectionView;
    
    NSMutableArray *notes;
}

@end

@implementation InnovListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        notes    = [[NSMutableArray alloc] initWithCapacity:20];
       // images             = [[NSMutableArray alloc] initWithCapacity:20];
       // text               = [[NSMutableArray alloc] initWithCapacity:20];
#warning listen for notes
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*
     CGRect quiltViewFrame = listContentView.frame;
     quiltViewFrame.origin.x = 0;
     quiltViewFrame.origin.y = 0;
     quiltView = [[TMQuiltView alloc] initWithFrame:quiltViewFrame];
     quiltView.bounces = NO;
     quiltView.delegate = self;
     quiltView.dataSource = self;
     quiltView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
     [listContentView addSubview:quiltView]; 
    
    quiltView = nil;
    
    [quiltView reloadData];
    */
    
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


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [quiltView reloadData];
}

 #pragma mark - TMQuiltViewDataSource
 
 - (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)quiltView {
 int cellCount = [availableTags count];
 for(int i = 0; i < [availableTags count]; ++i)
 cellCount+= [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count];
 
 return cellCount;
 }
 
#pragma mark - QuiltViewControllerDataSource

- (void) refreshImagesAndText
{
    [images removeAllObjects];
    [text   removeAllObjects];
    for(int i = 0; i < [availableTags count]; ++i)
    {
#warning re-add or do something else to designate tag
        //   [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@_header.png", ((Tag *)[availableTags objectAtIndex:i]).tagName]]];
        //   [text   addObject:@""];
        for(int j = 0; j < [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count]; ++j)
        {
            Note * note = [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] objectAtIndex:j];
            
            NoteContent *noteContent;
            for(int k = 0; k < [note.contents count]; ++k)
            {
                noteContent = [note.contents objectAtIndex:k];
                if([[noteContent getType] isEqualToString:kNoteContentTypePhoto]) break;
            }
            
            NSString *number = [NSString stringWithFormat:@"%d", j];
            
            [images addObject:noteContent];
            if(note.title) [text   addObject:note.title];
            else           [text   addObject: number];
        }
    }
}

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)TMQuiltView {
    return 0; //[images count];
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)aQuiltView cellAtIndexPath:(NSIndexPath *)indexPath {
    TMPhotoQuiltViewCell *cell = (TMPhotoQuiltViewCell *)[aQuiltView dequeueReusableCellWithReuseIdentifier:@"PhotoCell"];
    if (!cell) {
        cell = [[TMPhotoQuiltViewCell alloc] initWithReuseIdentifier:@"PhotoCell"];
    }
    if([[images objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) [cell.photoView setImage:[images objectAtIndex:indexPath.row]];
    else [cell.photoView loadImageFromMedia:[[images objectAtIndex:indexPath.row] getMedia]];
    
    //   if(![[text objectAtIndex:indexPath.row] isEqualToString:@""])
    cell.titleLabel.text = [text objectAtIndex:indexPath.row];
    
    return cell;
}
#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView {
    
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft
        || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        return 3;
    } else {
        return 2;
    }
}

- (CGFloat)quiltView:(TMQuiltView *)aQuiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    //   return ((TMPhotoQuiltViewCell *)[self quiltView:quiltView cellAtIndexPath:indexPath]).photoView.frame.size.height / [self quiltViewNumberOfColumns:aQuiltView];
    return 320/[self quiltViewNumberOfColumns:aQuiltView];
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    for(int i = 0; i < [availableTags count]; ++i)
    {
        if([[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count] <= index) index -= [[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] count];
        else
        {
            [self presentNote:[[tagNotesDictionary objectForKey:((Tag *)[availableTags objectAtIndex:i]).tagName] objectAtIndex:index]];
            return;
        }
        
    }
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
   
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
