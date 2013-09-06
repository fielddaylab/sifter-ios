//
//  SifterAppDelegate.m
//  Sifter
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright University of Wisconsin 2009. All rights reserved.
//

#import "SifterAppDelegate.h"

#import "AppModel.h"
#import "AppServices.h"
#import "InnovNoteModel.h"
#import "InnovViewController.h"

#import "UIColor+SifterColors.h"

@interface SifterAppDelegate()
{
    InnovViewController *innov;
}

@end

@implementation SifterAppDelegate

int readingCountUpToOneHundredThousand = 0;
int steps = 0;

@synthesize window;
@synthesize player;
@synthesize simpleMailShare;
@synthesize simpleTwitterShare;
@synthesize simpleFacebookShare;

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error) NSLog(@"Error: %@", error);
}

#pragma mark -
#pragma mark Application State

void uncaughtExceptionHandler(NSException *exception) {
    
    NSLog(@"Call Stack: %@", exception.callStackSymbols);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [AppModel sharedAppModel].serverURL = [NSURL URLWithString:SERVER];
    
#warning change game and finalize settings
    Game *game = [[Game alloc] init];
    game.gameId                   = GAME_ID;
    game.hasBeenPlayed            = YES;
    game.isLocational             = YES;
    game.showPlayerLocation       = YES;
    game.allowNoteComments        = YES;
    game.allowNoteLikes           = YES;
    game.rating                   = 5;
    game.pcMediaId                = 0;
    game.numPlayers               = 10;
    game.playerCount              = 5;
    game.gdescription             = @"Fun";
    game.name                     = @"Note Share";
    game.authors                  = @"Jacob Hanshaw";
    game.mapType                  = @"STREET";
    [AppModel sharedAppModel].currentGame = game;
    
    simpleMailShare     = [[SimpleMailShare alloc] init];
    simpleTwitterShare  = [[SimpleTwitterShare alloc] init];
    simpleFacebookShare = [[SimpleFacebookShare alloc] initWithAppName: @"Siftr" appUrl:HOME_URL];
#warning fix url and appname
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.m4v"]];
    UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    
    application.idleTimerDisabled = YES;
    
    //Log the current Language
	NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
	NSString *currentLanguage = [languages objectAtIndex:0];
	NSLog(@"Current Locale: %@", [[NSLocale currentLocale] localeIdentifier]);
	NSLog(@"Current language: %@", currentLanguage);
    
    [self setUpWithDefaultAppearance];
    //[[UIAccelerometer sharedAccelerometer] setUpdateInterval:0.2];
    
    //Init keys in UserDefaults in case the user has not visited the Sifter Settings page
	//To set these defaults, edit Settings.bundle->Root.plist
	[[AppModel sharedAppModel] initUserDefaults];
    
    innov = [[InnovViewController alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:innov];
    [self makeNavBarTransparent:nav.navigationBar];
    
    if([window respondsToSelector:@selector(setRootViewController:)])
        [window setRootViewController:nav];
    else
        [window addSubview:nav.view];
    
    [Crittercism enableWithAppID:@"51e40fef558d6a55a4000007"];
    
    NSDictionary *localNotifOptions = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if([localNotifOptions objectForKey:@"noteId"])
        [innov animateInNote: [[InnovNoteModel sharedNoteModel] noteForNoteId:[[localNotifOptions objectForKey:@"noteId"] intValue]]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    BOOL facebook = [simpleFacebookShare handleOpenURL:url];
    
    if (!url)
        return facebook;
    
    NSString *strPath = [[url host] lowercaseString];
    if ([strPath isEqualToString:@"games"] || [strPath isEqualToString:@"game"])
    {
        NSString *gameID = [url lastPathComponent];
        [[AppServices sharedAppServices] fetchOneGameGameList:[gameID intValue]];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [simpleFacebookShare handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSLog(@"Sifter: Application Became Active");
	[[AppModel sharedAppModel]       loadUserDefaults];
    [[AppServices sharedAppServices] resetCurrentlyFetchingVars];
    
    if([AppModel sharedAppModel].fallbackGameId != 0 && ![AppModel sharedAppModel].currentGame)
        [[AppServices sharedAppServices] fetchOneGameGameList:[AppModel sharedAppModel].fallbackGameId];
    
    [[[AppModel sharedAppModel]uploadManager] checkForFailedContent];
    
    [[InnovNoteModel sharedNoteModel] clearAllData];
    [[AppServices sharedAppServices] fetchGameNoteTagsAsynchronously:YES];
    
    [simpleFacebookShare handleDidBecomeActive];
    [[[MyCLController sharedMyCLController] locationManager] startUpdatingLocation];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (application.applicationState == UIApplicationStateInactive )
    {
        [innov.navigationController popToRootViewControllerAnimated:YES];
        
        NSDictionary *localNotifOptions = notification.userInfo;
        if([localNotifOptions objectForKey:@"noteId"])
        {
            Note * note = [[InnovNoteModel sharedNoteModel] noteForNoteId:[[localNotifOptions objectForKey:@"noteId"] intValue]];
            if(note)
            {
                [innov animateInNote: note];
                [[InnovNoteModel sharedNoteModel] setNoteAsPreviouslyDisplayed:note];
            }
        }
        //The application received the notification from an inactive state, i.e. the user tapped the "View" button for the alert.
        //If the visible view controller in your view controller stack isn't the one you need then show the right one.
    }
    
    if(application.applicationState == UIApplicationStateActive )
    {
        //The application received a notification in the active state, so you can display an alert view or do something appropriate.
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSLog(@"Sifter: Resigning Active Application");
	[[AppModel sharedAppModel] saveUserDefaults];
    [[[MyCLController sharedMyCLController] locationManager] stopUpdatingLocation];
}

-(void) applicationWillTerminate:(UIApplication *)application
{
	NSLog(@"Sifter: Terminating Application");
    [[AppModel sharedAppModel] saveUserDefaults];
    [[AppModel sharedAppModel] saveCOREData];
    
    [simpleFacebookShare close];
}

#pragma mark - Audio

- (void) playAudioAlert:(NSString*)wavFileName shouldVibrate:(BOOL)shouldVibrate
{
	if (shouldVibrate == YES) [NSThread detachNewThreadSelector:@selector(vibrate) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(playAudio:) toTarget:self withObject:wavFileName];
}

- (void)playAudio:(NSString*)wavFileName
{
	NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:wavFileName ofType:@"wav"]];
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    NSError* err;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL: url error:&err];
    [self.player setDelegate: self];
    
    if(err) NSLog(@"Appdelegate: Playing Audio: Failed with reason: %@", [err localizedDescription]);
    else [self.player play];
}

- (void)stopAudio
{
    if(self.player) [self.player stop];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [[AVAudioSession sharedInstance] setActive: NO error: nil];
}

- (void)vibrate
{
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)setUpWithDefaultAppearance
{
    
    [[UINavigationBar appearance]       setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    {
        // Load resources for iOS 6.1 or earlier
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        [[UIToolbar appearance]             setTintColor:[UIColor SifterColorToolBarTint]];
        [[UIBarButtonItem appearance]       setTintColor:[UIColor SifterColorBarButtonTint]];
        
        [[UISegmentedControl appearance]    setTintColor:[UIColor SifterColorSegmentedControlTint]];
        
        [[UISegmentedControl appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIFont fontWithName:@"HelveticaNeue-Light" size:12], UITextAttributeFont,
          [UIColor SifterColorWhite],                           UITextAttributeTextColor,
          [UIColor clearColor],                                 UITextAttributeTextShadowColor,
          nil]
                                                       forState:UIControlStateNormal];
        
        [[UISegmentedControl appearance]    setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor SifterColorWhite],                         UITextAttributeTextColor,
          [UIColor clearColor],                               UITextAttributeTextShadowColor,
          [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],    UITextAttributeFont,
          nil]
                                                          forState:UIControlStateSelected];
        
        [[UISearchBar appearance]           setTintColor:[UIColor SifterColorNavBarTint]];
        [[UISearchBar appearance]           setBackgroundColor:[UIColor clearColor]];
        [[UITabBar appearance]              setTintColor:[UIColor SifterColorTabBarTint]];
        [[UINavigationBar appearance]       setTintColor:[UIColor SifterColorNavBarTint]];
        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor SifterColorNavBarText],                      UITextAttributeTextColor,
          [UIColor clearColor],                               UITextAttributeTextShadowColor,
          [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],    UITextAttributeFont,
          nil]
         ];
        
    }
    else
    {
        // Load resources for iOS 7 or later
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
        
        [[UISegmentedControl appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIFont fontWithName:@"HelveticaNeue-Light" size:12], UITextAttributeFont,
          [UIColor SifterColorBlack],                           UITextAttributeTextColor,
          [UIColor clearColor],                                 UITextAttributeTextShadowColor,
          nil]
                                                       forState:UIControlStateNormal];
        
        [[UISegmentedControl appearance]    setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor SifterColorBlack],                         UITextAttributeTextColor,
          [UIColor clearColor],                               UITextAttributeTextShadowColor,
          [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],    UITextAttributeFont,
          nil]
                                                          forState:UIControlStateSelected];
        
        [[UINavigationBar appearance] setBarTintColor:[UIColor SifterColorNavBarTint]];
        [[UINavigationBar appearance] setTintColor:[UIColor SifterColorDarkGray]];
        self.window.rootViewController.edgesForExtendedLayout = UIRectEdgeAll;
        self.window.rootViewController.extendedLayoutIncludesOpaqueBars = NO;
    }
    
    [[UILabel appearance] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0]];
    [[UILabel appearanceWhenContainedIn:[UIButton class],        nil] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17]];
    [[UILabel appearanceWhenContainedIn:[UITableViewCell class], nil] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17]];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"HelveticaNeue-Light" size:12], UITextAttributeFont,
      [UIColor SifterColorDarkGray], UITextAttributeTextColor,
      nil]
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:
     [UIImage imageNamed:@"1pxColorClear"]
                                                      forState:UIControlStateNormal
                                                    barMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor SifterColorNavBarText],                      UITextAttributeTextColor,
      [UIColor clearColor],                               UITextAttributeTextShadowColor,
      [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],    UITextAttributeFont,
      nil]
     ];
    
    [[UITabBarItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor SifterColorTabBarText],                   UITextAttributeTextColor,
      [UIFont fontWithName:@"HelveticaNeue-Light" size:0.0], UITextAttributeFont,
      nil]
                                             forState:UIControlStateNormal];
}

- (void) makeNavBarTransparent: (UINavigationBar *) navBar
{
    navBar.translucent = YES;
    navBar.opaque = NO;
    navBar.alpha = 0.9f;
    if ([navBar respondsToSelector:@selector(shadowImage)])
        [navBar setShadowImage:[[UIImage alloc] init]];
}

#pragma mark Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end