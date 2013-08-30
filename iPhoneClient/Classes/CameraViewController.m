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
#import "NoteContent.h"
#import "CameraOverlayView.h"

#import "Logger.h"

#define ANIMATE_DURATION     0.5
#define ANIMATE_DELAY        1.0

@interface CameraViewController() <CameraOverlayViewDelegate>
{
    UIImagePickerController *picker;
    CameraOverlayView *overlay;
    
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
    
    picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Fixes missing status bar when cancelling picture pick from library
    if([UIApplication sharedApplication].statusBarHidden)
    {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
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
    CGRect frame = CGRectMake(0, 375, picker.view.frame.size.width, BUTTON_HEIGHT);
    if (picker.view.bounds.size.height > 480.0f)
        frame.origin.y = 422;
    
    overlay = [[CameraOverlayView alloc] initWithFrame:frame andDelegate:self];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraOverlayView = overlay;
    
    overlay.alpha = 0;
    [UIView animateWithDuration:ANIMATE_DURATION delay:ANIMATE_DELAY options:UIViewAnimationCurveEaseIn animations:^
    {
       overlay.alpha = 1;
    } completion:nil];
    
	[self presentModalViewController:picker animated:NO];
}

- (void)showLibraryButtonPressed:(id)sender
{
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if(sender != overlay) [self presentModalViewController:picker animated:NO];
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
    
    __weak CameraViewController *selfForBlock = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, (unsigned long)NULL), ^(void) {
        UIImage *image = [[info objectForKey:UIImagePickerControllerEditedImage] fixOrientation];
     //   image = [selfForBlock cropImage:image];
        selfForBlock.mediaData = UIImageJPEGRepresentation(image, 0.02);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [selfForBlock.editView updateImageView:selfForBlock.mediaData];
        });
        
        self.mediaData = [selfForBlock dataWithEXIFUsingData:selfForBlock.mediaData];
        
        NSString *newFilePath =[NSTemporaryDirectory() stringByAppendingString: [NSString stringWithFormat:@"%@image.jpg",[NSDate date]]];
        NSURL *imageURL = [[NSURL alloc] initFileURLWithPath: newFilePath];
        [self.mediaData writeToURL:imageURL atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[AppModel sharedAppModel] uploadManager]uploadContentForNoteId:selfForBlock.noteId withTitle:[NSString stringWithFormat:@"%@",[NSDate date]] withText:nil withType:kNoteContentTypePhoto withFileURL:imageURL];
        });
        
        if ([info objectForKey:UIImagePickerControllerReferenceURL] == NULL)
        {
            
            ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
            [al writeImageDataToSavedPhotosAlbum:selfForBlock.mediaData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 [al assetForURL:assetURL resultBlock:^(ALAsset *asset){}
                    failureBlock:^(NSError *error)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your privacy settings are disallowing us from saving to your camera roll. Go into System Settings to turn these settings off." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                          [alert show];
                      });
                  }
                  ];
             }];
            
        }
    });
    
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
    NSString *nameToDisplay = ([[AppModel sharedAppModel].displayName length] > 0) ? [AppModel sharedAppModel].displayName : [AppModel sharedAppModel].userName;
    NSString *descript = [[NSString alloc] initWithFormat: @"%@ %@: %@. %@: %@", NSLocalizedString(@"CameraImageTakenKey", @""), NSLocalizedString(@"CameraGameKey", @""), gameName, NSLocalizedString(@"CameraPlayerKey", @""), nameToDisplay];
    [exifDict setDescription: descript];
    
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
/*
- (UIImage *)cropImage:(UIImage *)oldImage
{
    CGRect rect;
    if(oldImage.size.height > oldImage.size.width)
        rect = CGRectMake(0, (oldImage.size.height - oldImage.size.width)/2, oldImage.size.width, oldImage.size.width);
    else
        rect = CGRectMake((oldImage.size.width - oldImage.size.height)/2, 0, oldImage.size.height, oldImage.size.height);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(oldImage.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:oldImage.scale orientation:oldImage.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}
*/

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