//
//  ARISAppDelegate.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright University of Wisconsin 2009. All rights reserved.
//

#import "AppModel.h"
#import "AppServices.h"

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "AudioToolbox/AudioToolbox.h"

#import "Reachability.h"

#import "Crittercism.h"

#import "SimpleMailShare.h"
#import "SimpleTwitterShare.h"
#import "SimpleFacebookShare.h"

#define SERVER                       @"http://dev.arisgames.org/server"
#define HOME_URL                     @"www.arisgames.org/yoi-server"
#define GAME_ID                      3434   //3434 for dev.arisgames.org/server    3371 for arisgames.org/yoi-server                  

@interface ARISAppDelegate : NSObject <AVAudioPlayerDelegate,UIApplicationDelegate, UIAccelerometerDelegate>
{
	UIWindow *window;
    AVAudioPlayer *player;
}

@property (nonatomic) UIWindow *window;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) SimpleMailShare     *simpleMailShare;
@property (nonatomic, strong) SimpleTwitterShare  *simpleTwitterShare;
@property (nonatomic, strong) SimpleFacebookShare *simpleFacebookShare;

- (void) vibrate;
- (void) playAudioAlert:(NSString*)wavFileName shouldVibrate:(BOOL)shouldVibrate;
- (void) stopAudio;
- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url;
- (void) startMyMotionDetect;
@end
