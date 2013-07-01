//
//  ARISAppDelegate.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright University of Wisconsin 2009. All rights reserved.
//

#import "ARISAppDelegate.h"

#import "InnovViewController.h"

@implementation ARISAppDelegate

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

- (void)applicationDidFinishLaunching:(UIApplication *)application
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
    simpleFacebookShare = [[SimpleFacebookShare alloc] initWithAppName: @"YOI" appUrl:HOME_URL];
#warning fix url and appname
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.m4v"]];
    UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    
    application.idleTimerDisabled = YES;
    
    //Log the current Language
	NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
	NSString *currentLanguage = [languages objectAtIndex:0];
	NSLog(@"Current Locale: %@", [[NSLocale currentLocale] localeIdentifier]);
	NSLog(@"Current language: %@", currentLanguage);
    
    //[[UIAccelerometer sharedAccelerometer] setUpdateInterval:0.2];
    
    //Init keys in UserDefaults in case the user has not visited the ARIS Settings page
	//To set these defaults, edit Settings.bundle->Root.plist
	[[AppModel sharedAppModel] initUserDefaults];

    InnovViewController *innov = [[InnovViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:innov];
    if([window respondsToSelector:@selector(setRootViewController:)])
        [window setRootViewController:nav];
    else
        [window addSubview:nav.view];
    
    [Crittercism enableWithAppID: @"5101a46d59e1bd498c000002"];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (!url)
        return NO;
    
    NSString *strPath = [[url host] lowercaseString];
    if ([strPath isEqualToString:@"games"] || [strPath isEqualToString:@"game"])
    {
        NSString *gameID = [url lastPathComponent];
        [[AppServices sharedAppServices] fetchOneGameGameList:[gameID intValue]];
    }
    return YES;
    //return [simpleFacebookShare handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [simpleFacebookShare handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSLog(@"ARIS: Application Became Active");
	[[AppModel sharedAppModel]       loadUserDefaults];
    [[AppServices sharedAppServices] resetCurrentlyFetchingVars];

    if([AppModel sharedAppModel].fallbackGameId != 0 && ![AppModel sharedAppModel].currentGame)
        [[AppServices sharedAppServices] fetchOneGameGameList:[AppModel sharedAppModel].fallbackGameId];
        
    [[[AppModel sharedAppModel]uploadManager] checkForFailedContent];
    
    [simpleFacebookShare handleDidBecomeActive];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"NSNotification: LowMemoryWarning");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"LowMemoryWarning" object:nil]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSLog(@"ARIS: Resigning Active Application");
	[[AppModel sharedAppModel] saveUserDefaults];
}

-(void) applicationWillTerminate:(UIApplication *)application
{
	NSLog(@"ARIS: Terminating Application");
	[[AppModel sharedAppModel] saveUserDefaults];
    [[AppModel sharedAppModel] saveCOREData];
    
    [simpleFacebookShare close];
}

- (void)startMyMotionDetect
{
    if(![AppModel sharedAppModel].motionManager.accelerometerAvailable) return;
    
    [AppModel sharedAppModel].motionManager.accelerometerUpdateInterval = 0.2;
    NSOperationQueue *motionQueue = [[NSOperationQueue alloc] init];
    [[AppModel sharedAppModel].motionManager startAccelerometerUpdatesToQueue: motionQueue withHandler:
        ^(CMAccelerometerData *data, NSError *error) { [self accelerometerData: data errorMessage: error];}
        ];
}

- (void)accelerometerData:(CMAccelerometerData *)data errorMessage:(NSError *)error
{
    float minAccelX = 1.2;
    float minAccelY = 1.2;
    float minAccelZ = 1.2;
    [AppModel sharedAppModel].averageAccelerometerReadingX = ([AppModel sharedAppModel].averageAccelerometerReadingX + data.acceleration.x)/2;
    [AppModel sharedAppModel].averageAccelerometerReadingY = ([AppModel sharedAppModel].averageAccelerometerReadingY + data.acceleration.y)/2;
    [AppModel sharedAppModel].averageAccelerometerReadingZ = ([AppModel sharedAppModel].averageAccelerometerReadingZ + data.acceleration.z)/2;
    if(readingCountUpToOneHundredThousand >= 100000){
        minAccelX = [AppModel sharedAppModel].averageAccelerometerReadingX * 2;
        minAccelY = [AppModel sharedAppModel].averageAccelerometerReadingY * 2;
        minAccelZ = [AppModel sharedAppModel].averageAccelerometerReadingZ * 2;
    }
    else readingCountUpToOneHundredThousand++;
    static BOOL beenhere;
    BOOL shake = FALSE;
    if (beenhere) return;
    beenhere = TRUE;
    if (data.acceleration.x > minAccelX || data.acceleration.x < (-1* minAccelX)){
        shake = TRUE;
        NSLog(@"Shaken X: %f", data.acceleration.x);
    }
    if (data.acceleration.y > minAccelY || data.acceleration.y < (-1* minAccelY)){
        shake = TRUE;
        NSLog(@"Shaken Y: %f", data.acceleration.y);
    }
    if (data.acceleration.z > minAccelZ || data.acceleration.z < (-1* minAccelZ)){
        shake = TRUE;
            NSLog(@"Shaken Z: %f", data.acceleration.x);
    }
    if (shake) {
        steps++;
        [self playAudioAlert:@"pingtone" shouldVibrate:YES]; 
    }
    beenhere = false;
    NSLog(@"Number of steps: %d", steps);
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

#pragma mark Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
