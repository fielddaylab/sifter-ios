//
//  AppModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <CoreLocation/CLLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreData/CoreData.h>
#import "Game.h"
#import "Media.h"
#import "Note.h"
#import "MediaCache.h"
#import "UploadMan.h"

@interface AppModel : NSObject <UIAccelerometerDelegate>
{
	NSUserDefaults *defaults;
	NSURL *serverURL;
    BOOL museumMode;
    BOOL skipGameDetails;
	Game *currentGame;
	UIAlertView *networkAlert;

    CMMotionManager *motionManager;

	int playerId;
	int fallbackGameId;
    int playerMediaId;
    int groupGame;
	NSString *groupName;
	NSString *userName;
	NSString *displayName;
	NSString *password;
	CLLocation *playerLocation;
    
    NSMutableArray *oneGameGameList;
    NSMutableArray *recentGamelist;
	NSMutableArray *playerList;
	NSMutableArray *nearbyLocationsList;

	NSMutableDictionary *gameMediaList;
    NSMutableArray *gameTagList;

    UIProgressView *progressBar;

    BOOL overlayIsVisible;

    //Accelerometer Data
    float averageAccelerometerReadingX;
    float averageAccelerometerReadingY;
    float averageAccelerometerReadingZ;
    
	//Training Flags
	BOOL hasSeenNearbyTabTutorial;
	BOOL hasSeenQuestsTabTutorial;
	BOOL hasSeenMapTabTutorial;
	BOOL hasSeenInventoryTabTutorial;
    BOOL profilePic,tabsReady,hidePlayers,isGameNoteList;
    BOOL hasReceivedMediaList;
    
    BOOL currentlyInteractingWithObject;

    //CORE Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    UploadMan *uploadManager;
    MediaCache *mediaCache;
}

@property(nonatomic, strong) NSURL *serverURL;
@property(readwrite) BOOL museumMode;
@property(readwrite) BOOL skipGameDetails;

@property(nonatomic, retain) CMMotionManager *motionManager;

@property(readwrite) BOOL profilePic;

@property(readwrite) BOOL hidePlayers;
@property(readwrite) BOOL isGameNoteList;

@property(readwrite) BOOL hasReceivedMediaList;

@property(readwrite) BOOL overlayIsVisible;

@property(readwrite) float averageAccelerometerReadingX;
@property(readwrite) float averageAccelerometerReadingY;
@property(readwrite) float averageAccelerometerReadingZ;

@property(nonatomic, strong) NSString *userName;
@property(nonatomic, strong) NSString *groupName;
@property(nonatomic, strong) NSString *displayName;
@property(nonatomic, strong) NSString *password;
@property(readwrite) int groupGame;
@property(readwrite) int playerId;
@property(readwrite) int fallbackGameId;//Used only to recover from crashes
@property(readwrite) int playerMediaId;

@property(nonatomic, strong) Game *currentGame;

@property(nonatomic, strong) NSURL *fileToDeleteURL;
@property(nonatomic, strong) NSMutableArray *oneGameGameList;
	
@property(nonatomic, strong) NSMutableArray *playerList;

@property(nonatomic, strong) NSMutableArray *nearbyLocationsList;	
@property(nonatomic, strong) CLLocation *playerLocation;

@property(nonatomic, strong) NSMutableArray *gameTagList;

@property(nonatomic, strong) NSMutableDictionary *gameMediaList;

@property(nonatomic, strong) UIAlertView *networkAlert;
@property(nonatomic, strong) UIProgressView *progressBar;

//Training Flags
@property(readwrite) BOOL hasSeenNearbyTabTutorial;
@property(readwrite) BOOL hasSeenQuestsTabTutorial;
@property(readwrite) BOOL hasSeenMapTabTutorial;
@property(readwrite) BOOL hasSeenInventoryTabTutorial;
@property(readwrite) BOOL tabsReady;

@property(readwrite) BOOL currentlyInteractingWithObject;

// CORE Data
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic, strong) UploadMan *uploadManager;
@property(nonatomic, strong) MediaCache *mediaCache;

+ (AppModel *)sharedAppModel;

- (id)init;
- (void)setPlayerLocation:(CLLocation *) newLocation;	
- (void)loadUserDefaults;
- (void)clearUserDefaults;
- (void)saveUserDefaults;
- (void)saveCOREData;
- (void)initUserDefaults;
- (void)clearGameLists;

- (Media *)mediaForMediaId:(int)mId;
- (Note *)noteForNoteId:(int)mId playerListYesGameListNo:(BOOL)playerorGame;

@end
