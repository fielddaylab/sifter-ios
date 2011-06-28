//
//  PanoramicViewController.h
//  ARIS
//
//  Created by Brian Thiel on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Panoramic.h"
#import "PLView.h"
#import "Media.h"
@interface PanoramicViewController : UIViewController <UIImagePickerControllerDelegate>{
    Panoramic *panoramic;
    IBOutlet UIView *viewImageContainer;
    IBOutlet	PLView	*plView;
    NSURLConnection *connection;
    NSMutableData* data; //keep reference to the data so we can collect it as it downloads
    Media *media;
    Media *overlayMedia;
    UIImagePickerController *imagePickerController;
    BOOL didLoadOverlay;
    BOOL finishedAlignment;
}

@property (nonatomic,retain)Panoramic *panoramic;
@property(nonatomic, retain) IBOutlet PLView	*plView;
@property(nonatomic, retain) IBOutlet UIView	*viewImageContainer;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) Media *overlayMedia;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (readwrite,assign) BOOL didLoadOverlay;
@property (readwrite,assign) BOOL finishedAlignment;


- (void)loadImage;
- (void)loadImageFromMedia:(Media *) aMedia;
-(IBAction) touchScreen;
@end