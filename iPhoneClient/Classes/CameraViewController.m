//
//  CameraViewController.m
//  ARIS
//
//  Created by David Gagnon on 3/4/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "CameraViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>

#import "InnovViewController.h"
#import "InnovNoteEditorViewController.h"

#import "UIImage+fixOrientation.h"
#import "NSMutableDictionary+ImageMetadata.h"

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "AppServices.h"
#import "Logger.h"

#import "NoteContent.h"

#define BUTTON_Y_OFFSET      10
#define BUTTON_WIDTH         78
#define BUTTON_HEIGHT        34
#define BUTTON_CORNER_RADIUS 15.0f
#define BUTTON_IMAGE_NAME    @"camera_roll.png"
#define ANIMATE_DURATION     0.5
#define ANIMATE_DELAY        1.0

#define CROP_BOX_IMAGE_WIDTH     321
#define CROP_BOX_IMAGE_HEIGHT    321

#define CROP_IMAGE_WIDTH     320
#define CROP_IMAGE_HEIGHT    320

@interface CameraViewController()
{
    UIView *cameraOverlay;
    UIButton *libraryButton;
    UIImagePickerController *picker;
    
    BOOL bringUpCamera;	
}

@property(nonatomic) NSData *mediaData;

@end

@implementation CameraViewController

@synthesize noteId, backView, editView, mediaData;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
    if ((self = [super initWithNibName:nibName bundle:nibBundle])) {
        self.title = NSLocalizedString(@"CameraTitleKey",@"");
        self.tabBarItem.image = [UIImage imageNamed:@"camera.png"];
        bringUpCamera = YES;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cameraOverlay = [[UIView alloc] initWithFrame:self.view.frame];
	
    libraryButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-BUTTON_WIDTH/2, BUTTON_Y_OFFSET, BUTTON_WIDTH, BUTTON_HEIGHT)];
    libraryButton.layer.borderWidth  = 1.0f;
    libraryButton.layer.borderColor  = [UIColor darkGrayColor].CGColor;
    libraryButton.backgroundColor    = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.25];
    libraryButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    
    [libraryButton setImage: [UIImage imageNamed:BUTTON_IMAGE_NAME] forState: UIControlStateNormal];
    [libraryButton setImage: [UIImage imageNamed:BUTTON_IMAGE_NAME] forState: UIControlStateHighlighted];
    [libraryButton addTarget:self action:@selector(showLibraryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [cameraOverlay addSubview:libraryButton];
    
    picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    
    UIImageView *cropBoxImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropBox.png"]];
    cropBoxImageView.center = cameraOverlay.center;
    [cameraOverlay addSubview:cropBoxImageView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(bringUpCamera){
        bringUpCamera = NO;
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self showCamera];
        else
            [self showLibraryButtonPressed:self];
    }
}

- (void)showCamera
{
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraOverlayView = cameraOverlay;
    libraryButton.alpha = 0;
    [UIView animateWithDuration:ANIMATE_DURATION delay:ANIMATE_DELAY options:UIViewAnimationCurveEaseIn animations:^
     {
         libraryButton.alpha = 1;
     } completion:nil];
    
	[self presentModalViewController:picker animated:NO];
}

- (void)showLibraryButtonPressed:(id)sender
{
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
	if (sender != libraryButton) [self presentModalViewController:picker animated:NO];
}

#pragma mark UIImagePickerControllerDelegate Protocol Methods
- (void)imagePickerController:(UIImagePickerController *)aPicker didFinishPickingMediaWithInfo:(NSDictionary  *)info
{
    if([self.editView isKindOfClass:[InnovNoteEditorViewController class]])
    {
        Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:self.noteId];
        for(int i = 0; i < [note.contents count]; ++i)
        {
            NoteContent *noteContent = [note.contents objectAtIndex:i];
            if([[noteContent getType] isEqualToString:kNoteContentTypePhoto])
            {
                if([[noteContent getUploadState] isEqualToString:@"uploadStateDONE"])
                    [[AppServices sharedAppServices] deleteNoteContentWithContentId:[noteContent getContentId] andNoteId:noteId];
                else
                    [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:self.noteId andFileURL:[NSURL URLWithString:[[noteContent getMedia] url]]];
                
                [note.contents removeObjectAtIndex:i];
                i--;
            }
        }
        
    }
    
    [aPicker dismissModalViewControllerAnimated:NO];
    
    [self.editView startSpinner];
    
    UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    image = [self cropImage:image];
    self.mediaData = UIImageJPEGRepresentation(image, 0.02);
    
    [self.editView updateImageView:self.mediaData];
    
    self.mediaData = [self dataWithEXIFUsingData:self.mediaData];
    
    NSString *newFilePath =[NSTemporaryDirectory() stringByAppendingString: [NSString stringWithFormat:@"%@image.jpg",[NSDate date]]];
    NSURL *imageURL = [[NSURL alloc] initFileURLWithPath: newFilePath];
    [mediaData writeToURL:imageURL atomically:YES];
    
    [[[AppModel sharedAppModel] uploadManager]uploadContentForNoteId:self.noteId withTitle:[NSString stringWithFormat:@"%@",[NSDate date]] withText:nil withType:kNoteContentTypePhoto withFileURL:imageURL];
    
    __weak CameraViewController *selfForBlock = self;
    if ([info objectForKey:UIImagePickerControllerReferenceURL] == NULL)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, (unsigned long)NULL), ^(void) {
            // If image not selected from camera roll
            ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
            [al writeImageDataToSavedPhotosAlbum:selfForBlock.mediaData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 [al assetForURL:assetURL resultBlock:^(ALAsset *asset){}
                    failureBlock:^(NSError *error)
                  {
                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your privacy settings are disallowing us from saving to your camera roll. Go into System Settings to turn these settings off." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                      [alert show];
                  }
                  ];
             }];
        });
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [[Logger sharedLogger] logError:error];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)aPicker
{
    [aPicker dismissModalViewControllerAnimated:NO];
    
    if([backView isKindOfClass:[InnovViewController class]])
    {
        [[AppServices sharedAppServices] deleteNoteWithNoteId:self.noteId];
        [[InnovNoteModel sharedNoteModel] removeNote:[[InnovNoteModel sharedNoteModel] noteForNoteId:self.noteId]];
    }
    [self.navigationController popToViewController:self.backView animated:YES];
}

- (NSMutableData*)dataWithEXIFUsingData:(NSData*)originalJPEGData
{
    NSMutableData* newJPEGData = [[NSMutableData alloc] init];
    NSMutableDictionary* exifDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* locDict = [[NSMutableDictionary alloc] init];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
	
    CGImageSourceRef img = CGImageSourceCreateWithData((__bridge CFDataRef)originalJPEGData, NULL);
    CLLocationDegrees exifLatitude = [AppModel sharedAppModel].playerLocation.coordinate.latitude;
    CLLocationDegrees exifLongitude = [AppModel sharedAppModel].playerLocation.coordinate.longitude;
	
    NSString* datetime = [dateFormatter stringFromDate:[AppModel sharedAppModel].playerLocation.timestamp];
	
    [exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    [exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
    
    NSString *gameName = [AppModel sharedAppModel].currentGame.name;
    NSString *descript = [[NSString alloc] initWithFormat: @"%@ %@: %@. %@: %@", NSLocalizedString(@"CameraImageTakenKey", @""), NSLocalizedString(@"CameraGameKey", @""), gameName, NSLocalizedString(@"CameraPlayerKey", @""), [[AppModel sharedAppModel] userName]];
    [exifDict setDescription: descript];
    
    //Ignore since it's nonsense
    //	[exifDict setObject:@"X" forKey:@"Orientation"];
    
    [locDict setObject:[AppModel sharedAppModel].playerLocation.timestamp forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
	
    if (exifLatitude <0.0){
        exifLatitude = exifLatitude*(-1);
        [locDict setObject:@"S" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
    }else{
        [locDict setObject:@"N" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
    }
    [locDict setObject:[NSNumber numberWithFloat:exifLatitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];
	
    if (exifLongitude <0.0){
        exifLongitude=exifLongitude*(-1);
        [locDict setObject:@"W" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
    }else{
        [locDict setObject:@"E" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
    }
    [locDict setObject:[NSNumber numberWithFloat:exifLongitude] forKey:(NSString*) kCGImagePropertyGPSLongitude];
	
    NSDictionary * properties = [[NSDictionary alloc] initWithObjectsAndKeys:
								 locDict, (NSString*)kCGImagePropertyGPSDictionary,
								 exifDict, (NSString*)kCGImagePropertyExifDictionary, nil];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)newJPEGData, CGImageSourceGetType(img), 1, NULL);
    CGImageDestinationAddImageFromSource(dest, img, 0, (__bridge CFDictionaryRef)properties);
    CGImageDestinationFinalize(dest);
	
    CFRelease(img);
    CFRelease(dest);
	
    return newJPEGData;
}

- (UIImage *)cropImage:(UIImage *)oldImage
{
    double xOffset = 0;
    double yOffset = 0;
    
#warning  MAGIC NUMBER
    int magicNumber = 8;
    
    double tabBarHeight = [[UITabBarController alloc] init].tabBar.frame.size.height;
    double pictureTakingHeight = [[UIScreen mainScreen] bounds].size.height - tabBarHeight;
    double imagePixelsPerScreenPixelWidth;
    double imagePixelsPerScreenPixelHeight;
    if(oldImage.size.width < oldImage.size.height)
    {
        imagePixelsPerScreenPixelWidth  = oldImage.size.width /[[UIScreen mainScreen] bounds].size.width;
        imagePixelsPerScreenPixelHeight = oldImage.size.height/pictureTakingHeight;
        xOffset = ([[UIScreen mainScreen] bounds].size.width/2-CROP_IMAGE_WIDTH/2) * imagePixelsPerScreenPixelWidth;
        yOffset = (pictureTakingHeight/2-CROP_IMAGE_HEIGHT/2 - magicNumber)        * imagePixelsPerScreenPixelHeight;
    }
    else
    {
        imagePixelsPerScreenPixelWidth  = oldImage.size.width /pictureTakingHeight;
        imagePixelsPerScreenPixelHeight = oldImage.size.height/[[UIScreen mainScreen] bounds].size.width;
        xOffset = (pictureTakingHeight/2-CROP_IMAGE_WIDTH/2 - magicNumber)          * imagePixelsPerScreenPixelWidth;
        yOffset = ([[UIScreen mainScreen] bounds].size.width/2-CROP_IMAGE_HEIGHT/2) * imagePixelsPerScreenPixelHeight;
    }
    
    CGRect rect = CGRectMake(xOffset, yOffset, CROP_IMAGE_WIDTH * imagePixelsPerScreenPixelWidth, CROP_IMAGE_HEIGHT * imagePixelsPerScreenPixelHeight);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(oldImage.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:oldImage.scale orientation:oldImage.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

#pragma mark Memory Management
- (void)didReceiveMemoryWarning
{
    NSLog(@"CAMERA DID RECEIVE MEMORY WARNING!");
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

@end
