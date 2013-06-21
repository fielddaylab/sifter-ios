//
//  CameraViewController.h
//  ARIS
//
//  Created by David Gagnon on 3/4/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

@protocol CameraViewControllerDelegate <NSObject>
@required
- (void) startSpinner;
- (void) updateImageView:(NSData *) image;
@end

@interface CameraViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (assign)    int noteId;
@property (nonatomic) UIViewController *backView;
@property (nonatomic) id<CameraViewControllerDelegate> editView;

@end
