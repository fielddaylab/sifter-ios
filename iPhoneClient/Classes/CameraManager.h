//
//  CameraViewController.h
//  ARIS
//
//  Created by David Gagnon on 3/4/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

@protocol CameraManagerDelegate <NSObject>
@required
- (void) startSpinner;
- (void) updateImageView:(NSData *) image;
- (void) dismiss;
@end

@interface CameraManager : NSObject

@property (assign)    int noteId;
@property (nonatomic, assign) BOOL deleteUponCancel;
@property (nonatomic, weak) id<CameraManagerDelegate> editView;

- (UIImagePickerController *)createPickerToTakePicture:(BOOL) takePicture;

@end