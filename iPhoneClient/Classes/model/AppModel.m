//
//  AppModel.m
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "AppModel.h"
#import "SifterAppDelegate.h"
#import "Media.h"
#import "AppServices.h"

@interface AppModel()
{
    NSMutableDictionary *cachedImages;
}

@end

@implementation AppModel

@synthesize serverURL;
@synthesize userName;
@synthesize groupName;
@synthesize groupGame;
@synthesize displayName;
@synthesize password;
@synthesize playerId;
@synthesize fallbackGameId;
@synthesize playerMediaId;
@synthesize oneGameGameList;
@synthesize currentGame;
@synthesize playerList;
@synthesize playerLocation;
@synthesize networkAlert;
@synthesize gameMediaList;
@synthesize nearbyLocationsList;
@synthesize gameTagList;
@synthesize progressBar;
@synthesize uploadManager;
@synthesize mediaCache;
@synthesize hasReceivedMediaList;
@synthesize fileToDeleteURL;

+ (id)sharedAppModel
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

#pragma mark Init/dealloc
-(id)init
{
    self = [super init];
    if (self)
    {
		//Init USerDefaults
		defaults      = [NSUserDefaults standardUserDefaults];
        cachedImages = [[NSMutableDictionary alloc] init];
		gameMediaList = [[NSMutableDictionary alloc] initWithCapacity:10];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearGameLists) name:@"NewGameSelected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addImageToCache:) name:@"ImageReady" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCache:) name:@"UIApplicationDidReceiveMemoryWarningNotification" object:nil];
	}
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark User Defaults

-(void)loadUserDefaults
{
	NSLog(@"ARIS: Loading User Defaults");
	[defaults synchronize];
    
    //Safe to load defaults
    
    if(self.playerId == 0)
    {
        self.playerId        = [defaults integerForKey:@"playerId"];
        self.playerMediaId   = [defaults integerForKey:@"playerMediaId"];
        self.userName        = [defaults objectForKey:@"userName"];
        self.displayName     = [defaults objectForKey:@"displayName"];
        self.groupName       = [defaults objectForKey:@"groupName"];
        self.groupGame       = [[defaults objectForKey:@"groupName"] intValue];
    }
    
    self.fallbackGameId = [defaults integerForKey:@"gameId"];
}

-(void)clearGameLists
{
    NSLog(@"Clearing Game Lists");
    [gameMediaList     removeAllObjects];
}

-(void)clearUserDefaults
{
	NSLog(@"Clearing User Defaults");
    [AppModel sharedAppModel].currentGame = nil;
    [AppModel sharedAppModel].playerId       = 0;
    [AppModel sharedAppModel].fallbackGameId = 0;
    [AppModel sharedAppModel].playerMediaId  = -1;
    [AppModel sharedAppModel].userName       = @"";
    [AppModel sharedAppModel].displayName    = @"";
    [defaults setInteger:playerId       forKey:@"playerId"];
    [defaults setInteger:fallbackGameId forKey:@"gameId"];
    [defaults setInteger:playerMediaId  forKey:@"playerMediaId"];
    [defaults setObject:userName        forKey:@"userName"];
    [defaults setObject:displayName     forKey:@"displayName"];
       
	[defaults synchronize];
}

-(void)saveUserDefaults
{
	NSLog(@"Model: Saving User Defaults");
	
	[defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVerison"];
	[defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBuildNumber"]   forKey:@"buildNum"];
    
    [defaults setInteger:playerId                 forKey:@"playerId"];
    [defaults setInteger:playerMediaId            forKey:@"playerMediaId"];
    [defaults setInteger:fallbackGameId           forKey:@"gameId"];
    [defaults setObject:userName                  forKey:@"userName"];
    [defaults setObject:displayName               forKey:@"displayName"];
	[defaults synchronize];
}

-(void)saveCOREData
{
    NSError *error = nil;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#warning add
           // [[RootViewController sharedRootViewController] showAlert:@"Error saving to disk" message:[NSString stringWithFormat:@"%@",[error userInfo]]];
        }
    }
}

-(void)initUserDefaults
{
    uploadManager = [[UploadMan alloc]  init];
    mediaCache    = [[MediaCache alloc] init];
}

#pragma mark Setters/Getters

- (void)setPlayerLocation:(CLLocation *) newLocation
{
	playerLocation = newLocation;
	
	//Tell the model to update the server and fetch any nearby locations
	[[AppServices sharedAppServices] updateServerWithPlayerLocation];	
	
    NSLog(@"NSNotification: PlayerMoved");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"PlayerMoved" object:nil]];
}

#pragma mark Retrieving Cached Objects

-(void) addImageToCache:(NSNotification *) notif
{
    NSString *key  = [notif.userInfo objectForKey:@"mediaId"];
    UIImage *image = [notif.userInfo objectForKey:@"image"];
    
    if([key length] > 0 && image)
        [cachedImages setObject:image forKey:key];
}

-(void) clearCache:(NSNotification *) notif
{
    [cachedImages removeAllObjects];
}

-(UIImage *) cachedImageForMediaId:(int) mId
{
    return [cachedImages objectForKey:[NSString stringWithFormat:@"%d", mId]];
}

-(void) clearCachedImages
{
    [cachedImages removeAllObjects];
}

-(Media *)mediaForMediaId:(int)mId
{
    if(mId == 0) return nil;
	return [mediaCache mediaForMediaId:mId];
}

#pragma mark Core Data
/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext
{
    if (managedObjectContext != nil)
        return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if(managedObjectModel != nil)
        return managedObjectModel;
        
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}

/**
  Returns the path to the application's Documents directory.
  */
- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"UploadContent.sqlite"]];
    NSError *error = nil;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
        NSLog(@"AppModel: Error getting the persistentStoreCoordinator");
	
    return persistentStoreCoordinator;
}

@end
