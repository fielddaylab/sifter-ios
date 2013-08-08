//
//  CustomImagePickerController.m
//  YOI
//
//  Created by Jacob Hanshaw on 8/8/13.
//
//

#import "CustomImagePickerController.h"

#define BUTTON_Y_OFFSET      10
#define BUTTON_WIDTH         78
#define BUTTON_HEIGHT        35
#define BUTTON_CORNER_RADIUS 15.0f
#define BUTTON_IMAGE_NAME    @"camera_roll.png"

@interface CustomImagePickerController()
{
    UIView *touchCapturer;
}

@end

@implementation CustomImagePickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        touchCapturer = [[UIView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:touchCapturer];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];
    
    for(UIView *view in self.view.subviews)
    {
        if([view isKindOfClass:[UIButton class]])
        [view touchesBegan:touches withEvent:event];
    }
    
    UIButton *libraryButton = (UIButton *)self.cameraOverlayView;
    
    CGRect flashButtonRect = libraryButton.hidden ? CGRectMake(20, BUTTON_Y_OFFSET, 200, BUTTON_HEIGHT) : CGRectMake(0, 20, 80, BUTTON_HEIGHT);
    
    UITouch* touch = [touches anyObject];
    if(CGRectContainsPoint(flashButtonRect, [touch locationInView:self.view]))
    {
        libraryButton.hidden = !libraryButton.hidden;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
