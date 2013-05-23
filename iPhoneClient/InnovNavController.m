//
//  InnovNavController.m
//  YOI
//
//  Created by Jacob James Hanshaw on 5/22/13.
//
//

#import "InnovNavController.h"
#import <QuartzCore/QuartzCore.h>

#import "InnovViewController.h"

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
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(0, 0, 30, 30);
    [switchButton addTarget:self action:@selector(switchViews) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateNormal];
    [switchButton setBackgroundImage: [UIImage imageNamed:@"noteicon.png"] forState:UIControlStateHighlighted];
    switchViewsBarButton = [[UIBarButtonItem alloc] initWithCustomView:switchButton];
    self.navigationItem.leftBarButtonItem = switchViewsBarButton;
    
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    searchBar.barStyle = UIBarStyleBlack;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, self.navigationBar.frame.size.height)];
    searchBarView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    searchBar.delegate = self;
    [searchBarView addSubview:searchBar];
    self.navigationItem.titleView = searchBarView;
    
    settingsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    settingsView.layer.anchorPoint = CGPointMake(1, 0);
    CGRect settingsLocation = settingsView.frame;
    settingsLocation.origin.x = self.view.frame.size.width  - settingsView.frame.size.width;
    settingsLocation.origin.y = 0;
    settingsView.frame = settingsLocation;
    
    settingsView.hidden = YES;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [searchBar resignFirstResponder];
    [settingsView hide];
}

- (void) switchViews
{
#warning close scope
   /* [UIView beginAnimations:@"Button Flip" context:nil];
    [UIView setAnimationDuration:1.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition: transition forView:switchViewsBarButton.customView cache:YES];
    [((UIButton *)switchViewsBarButton.customView) setBackgroundImage: [UIImage imageNamed:newButtonImageName] forState:UIControlStateNormal];
    [((UIButton *)switchViewsBarButton.customView) setBackgroundImage: [UIImage imageNamed:newButtonImageName] forState:UIControlStateHighlighted];
    [UIView commitAnimations]; 
     [((InnovViewController *)[self.navigationController.viewControllers objectAtIndex:0]) switchViews]; */
}

- (void)settingsPressed
{
    if(![self.view.subviews containsObject:settingsView])
    {
        [self.view addSubview:settingsView];
        [settingsView show];
    }
    else
    {
        [settingsView hide];
    }
}

- (void) showProfile
{
    #warning unimplemented
}

- (void) link
{
    #warning unimplemented
}

- (void) showAbout
{
    #warning unimplemented
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end