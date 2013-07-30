//
//  ARISAppDelegate.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright University of Wisconsin 2009. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "AudioToolbox/AudioToolbox.h"

#import "Reachability.h"

#import "Crittercism.h"

#import "SimpleMailShare.h"
#import "SimpleTwitterShare.h"
#import "SimpleFacebookShare.h"

#define SERVER                       @"http://arisgames.org/server"  //dev.
#define HOME_URL                     @"www.arisgames.org/yoi"
#define GAME_ID                      10690            // 3438 on dev      10690 on prod

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
@end