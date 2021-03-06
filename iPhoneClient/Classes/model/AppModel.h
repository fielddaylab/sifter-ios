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
	Game *currentGame;
	UIAlertView *networkAlert;

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
    
    BOOL profilePic,tabsReady,hidePlayers,isGameNoteList;
    BOOL hasReceivedMediaList;

    //CORE Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    UploadMan *uploadManager;
    MediaCache *mediaCache;
}

@property(nonatomic, strong) NSURL *serverURL;

@property(readwrite) BOOL hasReceivedMediaList;

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

- (void)clearCachedImages;
- (UIImage *)cachedImageForMediaId:(int) mId;
- (Media *)mediaForMediaId:(int)mId;

@end