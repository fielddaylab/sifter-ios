//
//  InnovNoteEditorViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 4/5/13.
//
//

#import "InnovNoteEditorViewController.h"
#import "AppModel.h"
#import "AppServices.h"
#import "InnovViewController.h"
#import "CameraViewController.h"
#import "Tag.h"
#import "TagCell.h"

@interface InnovNoteEditorViewController ()

@end

@implementation InnovNoteEditorViewController

@synthesize note, delegate, isEditable;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewFromModel) name:@"NewNoteListReady" object:nil];
        
        gameTagList = [[NSMutableArray alloc]initWithCapacity:10];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle: @"Cancel"
                                                                   style: UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(backButtonTouchAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: @"Share"
                                                                   style: UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(backButtonTouchAction:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    [[AVAudioSession sharedInstance] setDelegate: self];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    if(note.noteId == 0)
    {
        note = [[Note alloc]init];
        note.creatorId = [AppModel sharedAppModel].playerId;
        note.username = [AppModel sharedAppModel].userName;
        note.noteId = [[AppServices sharedAppServices] createNoteStartIncomplete];
        note.showOnList = YES;
        note.showOnMap  = YES;
#warning should allows show on List and Map?
        if(note.noteId == 0)
        {
            [self backButtonTouchAction:[[UIButton alloc] init]];
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"NoteEditorCreateNoteFailedKey", @"") message: NSLocalizedString(@"NoteEditorCreateNoteFailedMessageKey", @"") delegate:self.delegate cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
            [alert show];
        }
        [self cameraButtonTouchAction];
    }
    else
    {
#warning when do we edit, populate view if editable
    }
    
    [[AppModel sharedAppModel].playerNoteList setObject:note forKey:[NSNumber numberWithInt:note.noteId]];
    
    [self refreshCategories];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(!self.note || cancelled) return;

    self.note.title = captionTextView.text;
    if(([note.title length] == 0)) note.title = @"";
    [[AppServices sharedAppServices] updateNoteWithNoteId:self.note.noteId title:self.note.title publicToMap:self.note.showOnMap publicToList:self.note.showOnList];
    [[AppServices sharedAppServices] setNoteCompleteForNoteId:self.note.noteId];
    
    if([delegate isKindOfClass:[InnovViewController class]]) ((InnovViewController *)self.delegate).noteToAdd = self.note;
    
    [[AppModel sharedAppModel].playerNoteList setObject:self.note forKey:[NSNumber numberWithInt:self.note.noteId]];
    
#warning point where added to map may change
    [[AppServices sharedAppServices] dropNote:self.note.noteId atCoordinate:[AppModel sharedAppModel].playerLocation.coordinate];
    self.note.dropped = YES;
}

- (IBAction)recordButtonPressed:(id)sender
{
  #warning unimplemented  
}

- (IBAction)deleteAudioButtonPressed:(id)sender
{
   #warning unimplemented 
}

- (IBAction)backButtonTouchAction: (id) sender
{
    cancelled = ([sender isKindOfClass: [UIBarButtonItem class]] && [((UIBarButtonItem *) sender).title isEqualToString:@"Cancel"]);
    if(!isEditable && !([sender isKindOfClass: [UIBarButtonItem class]] && [((UIBarButtonItem *) sender).title isEqualToString:@"Share"]))
    {
        [[AppServices sharedAppServices] deleteNoteWithNoteId:self.note.noteId];
        [[AppModel sharedAppModel].playerNoteList removeObjectForKey:[NSNumber numberWithInt:self.note.noteId]];
        
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSInteger)supportedInterfaceOrientations
{
    NSInteger mask = 0;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeLeft])
        mask |= UIInterfaceOrientationMaskLandscapeLeft;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationLandscapeRight])
        mask |= UIInterfaceOrientationMaskLandscapeRight;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortrait])
        mask |= UIInterfaceOrientationMaskPortrait;
    if ([self shouldAutorotateToInterfaceOrientation: UIInterfaceOrientationPortraitUpsideDown])
        mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    return mask;
}

#pragma mark UITextView methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [captionTextView resignFirstResponder];
}

-(void)cameraButtonTouchAction
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        CameraViewController *cameraVC = [[CameraViewController alloc] initWithNibName:@"Camera" bundle:nil];
        
        if(isEditable) cameraVC.backView = self;
        else cameraVC.backView = self.delegate;
        cameraVC.parentDelegate = self.delegate;
        cameraVC.showVid = YES;
        cameraVC.editView = self;
        cameraVC.noteId = self.note.noteId;
        
        [self.navigationController pushViewController:cameraVC animated:NO];
    }
}

/*
-(void)mapButtonTouchAction
{
    /*if(self.note.dropped){
     
     self.mapButton.selected = NO;
     self.note.dropped = NO;
     [[AppServices sharedAppServices]deleteNoteLocationWithNoteId:self.note.noteId];
     
     }
     else{ */ /*
    DropOnMapViewController *mapVC = [[DropOnMapViewController alloc] initWithNibName:@"DropOnMapViewController" bundle:nil] ;
    mapVC.noteId = self.note.noteId;
    mapVC.delegate = self;
    self.noteValid = YES;
    self.mapButton.selected = YES;
    
    [self.navigationController pushViewController:mapVC animated:NO];
    //}
}
*/

/*
-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            if([AppModel sharedAppModel].currentGame.allowShareNoteToList){
                self.note.showOnList = YES;
                self.note.showOnMap = NO;
                self.sharingLabel.text = NSLocalizedString(@"NoteEditorListOnlyKey", @"");
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NoteEditorNotAllowedKey", @"") message: NSLocalizedString(@"NoteEditorNotAllowedSharingToListsMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
                
                [alert show];
            }
            break;
        case 1:
        {
            if([AppModel sharedAppModel].currentGame.allowShareNoteToMap){
                self.note.showOnList = NO;
                self.note.showOnMap = YES;
                self.sharingLabel.text = NSLocalizedString(@"NoteEditorMapOnlyKey", @"");
                if(!self.note.dropped){
                    [[AppServices sharedAppServices] dropNote:self.note.noteId atCoordinate:[AppModel sharedAppModel].playerLocation.coordinate];
                    self.note.dropped = YES;
                    self.mapButton.selected = YES;
                }
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NoteEditorNotAllowedKey", @"") message:NSLocalizedString(@"NoteEditorNotAllowedSharingToMapMessageKey", @"") delegate: self cancelButtonTitle:NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
                
                [alert show];
            }
            break;
        }
        case 2:{
            if([AppModel sharedAppModel].currentGame.allowShareNoteToMap && ([AppModel sharedAppModel].currentGame.allowShareNoteToList)){
                self.note.showOnList = YES;
                self.note.showOnMap = YES;
                self.sharingLabel.text = NSLocalizedString(@"NoteEditorListAndMapKey", @"");
                if(!self.note.dropped){
                    if(!self.note.dropped){
                        [[AppServices sharedAppServices] dropNote:self.note.noteId atCoordinate:[AppModel sharedAppModel].playerLocation.coordinate];
                        self.note.dropped = YES;
                        self.mapButton.selected = YES;
                    }
                }
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NoteEditorNotAllowedKey", @"") message:NSLocalizedString(@"NoteEditorNotAllowedOneOrMoreMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
                
                [alert show];
            }
            break;
        }
        case 3:
            self.note.showOnList = NO;
            self.note.showOnMap = NO;
            self.sharingLabel.text = NSLocalizedString(@"NoneKey", @"");
            break;
        default:
            break;
    }
    [[AppServices sharedAppServices] updateNoteWithNoteId:self.note.noteId title:self.textField.text publicToMap:self.note.showOnMap publicToList:self.note.showOnList];
}
*/

#pragma mark custom methods, logic

- (void)refreshViewFromModel
{
    note = [[[AppModel sharedAppModel] playerNoteList] objectForKey:[NSNumber numberWithInt:note.noteId]];
    [self addCDUploadsToNote];
}

-(void)addCDUploadsToNote
{
    for(int x = [self.note.contents count]-1; x >= 0; x--)
    {
        //Removes note contents that are not done uploading, because they will all be added again right after this loop
        if((NSObject <NoteContentProtocol> *)[[self.note.contents objectAtIndex:x] managedObjectContext] == nil ||
           ![[[self.note.contents objectAtIndex:x] getUploadState] isEqualToString:@"uploadStateDONE"])
            [self.note.contents removeObjectAtIndex:x];
    }
    
    NSArray *uploadContentsForNote = [[[AppModel sharedAppModel].uploadManager.uploadContentsForNotes objectForKey:[NSNumber numberWithInt:self.note.noteId]]allValues];
    [self.note.contents addObjectsFromArray:uploadContentsForNote];
    NSLog(@"InnovNoteEditorVC: Added %d upload content(s) to note",[uploadContentsForNote count]);
}

#pragma mark Table view methods

-(void)refreshCategories
{
    [gameTagList removeAllObjects];
    for(int i = 0; i < [[AppModel sharedAppModel].gameTagList count];i++){
            [gameTagList addObject:[[AppModel sharedAppModel].gameTagList objectAtIndex:i]];
    }
    [tagTableView reloadData];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *tempCell = (TagCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (![tempCell respondsToSelector:@selector(nameLabel)]){
        //[tempCell release];
        tempCell = nil;
    }
    TagCell *cell = (TagCell *)tempCell;
    
    
    if (cell == nil) {
        // Create a temporary UIViewController to instantiate the custom cell.
        UIViewController *temporaryController = [[UIViewController alloc] initWithNibName:@"TagCell" bundle:nil];
        // Grab a pointer to the custom cell.
        cell = (TagCell *)temporaryController.view;
        // Release the temporary UIViewController.
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if([gameTagList count] == 0) cell.nameLabel.text = @"No Categories in Application";
    else cell.nameLabel.text = [[gameTagList objectAtIndex:indexPath.row] tagName];
    
    if([self.note.tags count] > 0 && indexPath.row == ((Tag *)[self.note.tags objectAtIndex:0]).tagId) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    return cell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSIndexPath *oldIndex = [tableView indexPathForSelectedRow];
    [tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
    [[AppServices sharedAppServices] deleteTagFromNote:self.note.noteId tagId:indexPath.row];
    [self.note.tags removeAllObjects];
    return indexPath;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    //add tag to note;
    Tag *tempTag =[[Tag alloc]init];
    tempTag.tagName = cell.nameLabel.text;
    [self.note.tags addObject:tempTag];
    [[AppServices sharedAppServices] addTagToNote:self.note.noteId tagName:cell.nameLabel.text];

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if(gameTagList.count > 0)
                return [gameTagList count];
            else
                return 1;
            break;
        default:
            break;
    }
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"Categories";
            break;
        default:
            break;
    }
    return @"ERROR";
}

- (void)dealloc
{
    [[AVAudioSession sharedInstance] setDelegate: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    imageView = nil;
    captionTextView = nil;
    recordButton = nil;
    deleteAudioButton = nil;
    tagTableView = nil;
    [super viewDidUnload];
}


@end
