//
//  InnovNavController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovNavController.h"
#import <QuartzCore/QuartzCore.h>

#import "InnovSettingsView.h"

@interface InnovNavController ()

@end

@implementation InnovNavController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width  - settingsView.frame.size.width;
    settingsLocation.origin.y = 0;
    settingsView.frame = settingsLocation;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
