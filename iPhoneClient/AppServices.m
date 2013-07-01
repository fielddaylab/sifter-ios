//
//  AppServices.m
//  ARIS
//
//  Created by David J Gagnon on 5/11/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "AppServices.h"

#import "AppModel.h"
#import "InnovNoteModel.h"
#import "ARISUploader.h"
#import "ARISAppDelegate.h"
#import "Logger.h"

#import "Tag.h"
#import "Media.h"
#import "Note.h"
#import "Comment.h"
#import "NoteContent.h"

#import "JSON.h"
#import "JSONResult.h"
#import "JSONConnection.h"

static const int kDefaultCapacity = 10;
static const BOOL kEmptyBoolValue = NO;
static const int kEmptyIntValue = 0;
static const float kEmptyFloatValue = 0.0;
static const double kEmptyDoubleValue = 0.0;
NSString *const kARISServerServicePackage = @"v1";

BOOL currentlyFetchingOneGame;
BOOL currentlyUpdatingServerWithPlayerLocation;
BOOL currentlyUpdatingServerWithMapViewed;

@interface AppServices()

- (BOOL)      validBoolForKey:  (NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (NSInteger) validIntForKey:   (NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (float)     validFloatForKey: (NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (double)    validDoubleForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (id)        validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;

@end

@implementation AppServices

@synthesize isCurrentlyFetchingGameNoteList, shouldIgnoreResults;

+ (id)sharedAppServices
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void) resetCurrentlyFetchingVars
{
    shouldIgnoreResults                        = NO;
    currentlyFetchingOneGame                   = NO;
    isCurrentlyFetchingGameNoteList            = NO;
    currentlyUpdatingServerWithMapViewed       = NO;
    currentlyUpdatingServerWithPlayerLocation  = NO;
}

#pragma mark Communication with Server
- (void)login
{
	NSArray *arguments = [NSArray arrayWithObjects:[AppModel sharedAppModel].userName, [AppModel sharedAppModel].password, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"players"
                                                              andMethodName:@"getLoginPlayerObject"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseLoginResponseFromJSON:)];
}

- (void)registerNewUser:(NSString*)userName password:(NSString*)pass
			  firstName:(NSString*)firstName lastName:(NSString*)lastName email:(NSString*)email
{
	NSLog(@"AppModel: New User Registration Requested");
	//createPlayer($strNewUserName, $strPassword, $strFirstName, $strLastName, $strEmail)
	NSArray *arguments = [NSArray arrayWithObjects:userName, pass, firstName, lastName, email, nil];
    [AppModel sharedAppModel].userName = userName;
    [AppModel sharedAppModel].password = pass;
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName:@"players"
                                                              andMethodName:@"createPlayer"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseSelfRegistrationResponseFromJSON:)];
}

- (void)createUserAndLoginWithGroup:(NSString *)groupName
{
	NSArray *arguments = [NSArray arrayWithObjects:groupName, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"players"
                                                              andMethodName:@"createPlayerAndGetLoginPlayerObject"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseLoginResponseFromJSON:)];
}

-(void) uploadPlayerPicMediaWithFileURL:(NSURL *)fileURL
{
    ARISUploader *uploader = [[ARISUploader alloc]initWithURLToUpload:fileURL gameSpecific:NO delegate:self doneSelector:@selector(playerPicUploadDidfinish: ) errorSelector:@selector(playerPicUploadDidFail:)];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:2];
    [userInfo setValue:kNoteContentTypePhoto forKey: @"type"];
    [userInfo setValue:fileURL forKey:@"url"];
	[uploader setUserInfo:userInfo];
	
	NSLog(@"Model: Uploading File. gameID:%d ",[AppModel sharedAppModel].currentGame.gameId);
	
	//ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[[[RootViewController sharedRootViewController] showWaitingIndicator:@"Uploading" displayProgressBar:YES];
	//[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
    
	[uploader upload];
}

-(void) updatePlayer:(int)playerId withName:(NSString *)name andImage:(int)mid
{
    if(playerId != 0)
    {
        NSLog(@"AppModel: Updating Player info: %@ %d", name, mid);
        
        //Call server service
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",playerId],
                              name,
                              [NSString stringWithFormat:@"%d",mid],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"players"
                                                                 andMethodName:@"updatePlayerNameMedia"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        [jsonConnection performAsynchronousRequestWithHandler:nil];
    }
    else
        NSLog(@"Tried updating non-existent player! (playerId = 0)");
}

-(void)resetAndEmailNewPassword:(NSString *)email
{
    NSLog(@"Resetting Email: %@",email);
    NSArray *arguments = [NSArray arrayWithObjects:
                          email,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]
                                      initWithServer:[AppModel sharedAppModel].serverURL
                                      andServiceName:@"players"
                                      andMethodName:@"resetAndEmailNewPassword"
                                      andArguments:arguments
                                      andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:
     @selector(parseResetAndEmailNewPassword:)];
}

- (void)updateServerGameSelected
{
	NSLog(@"Model: Game %d Selected, update server", [AppModel sharedAppModel].currentGame.gameId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"updatePlayerLastGame"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
    
}

-(void)parseResetAndEmailNewPassword:(JSONResult *)jsonResult
{
#warning add?
    /*
     if(jsonResult == nil)
     [[RootViewController sharedRootViewController] showAlert:NSLocalizedString(@"ForgotPasswordTitleKey", nil) message:NSLocalizedString(@"ForgotPasswordMessageKey", nil)];
     else
     [[RootViewController sharedRootViewController] showAlert:NSLocalizedString(@"ForgotEmailSentTitleKey", @"") message:NSLocalizedString(@"ForgotMessageKey", @"")];
     */
}

- (void)dropNote:(int)noteId atCoordinate:(CLLocationCoordinate2D)coordinate
{
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  [NSString stringWithFormat:@"%f",coordinate.latitude],
						  [NSString stringWithFormat:@"%f",coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"dropNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(void)updateCommentWithId:(int)noteId andTitle:(NSString *)title andRefresh:(BOOL)refresh
{
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",noteId],
                          title,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateComment"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    
    if(refresh)
    {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt: noteId],@"noteId", nil];
        [jsonConnection performAsynchronousRequestWithHandler:@selector(updateNoteAfterRequest:) andUserInfo:userInfo];
    }
    else
        [jsonConnection performAsynchronousRequestWithHandler:nil];
}

-(void)likeNote:(int)noteId
{
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"likeNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(void)unLikeNote:(int)noteId
{
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"unlikeNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

#pragma mark Flagging Server Updates

-(void)flagNote:(int)noteId
{
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"flagNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(void)unFlagNote:(int)noteId
{
    NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"unflagNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

#pragma mark Sharing Note Server Updates

- (void)sharedNoteToFacebook:(int)noteId
{
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:noteId];
    note.facebookShareCount++;
    [[InnovNoteModel sharedNoteModel] updateNote:note];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"sharedNoteToFacebook"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

- (void)sharedNoteToTwitter:(int)noteId
{
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:noteId];
    note.twitterShareCount++;
    [[InnovNoteModel sharedNoteModel] updateNote:note];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"sharedNoteToTwitter"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

- (void)sharedNoteToPinterest:(int)noteId
{
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:noteId];
    note.pinterestShareCount++;
    [[InnovNoteModel sharedNoteModel] updateNote:note];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"sharedNoteToPinterest"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

- (void)sharedNoteToEmail:(int)noteId
{
    Note *note = [[InnovNoteModel sharedNoteModel] noteForNoteId:noteId];
    note.emailShareCount++;
    [[InnovNoteModel sharedNoteModel] updateNote:note];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"sharedNoteToEmail"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(int)addCommentToNoteWithId:(int)noteId andTitle:(NSString *)title
{
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",noteId],
                          title,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addCommentToNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
	
	if (!jsonResult) return 0;
	else             return [(NSDecimalNumber*)jsonResult.data intValue];
}

-(void)setNoteCompleteForNoteId:(int)noteId
{
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",noteId],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"setNoteComplete"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performSynchronousRequest];
}

-(int)createNote
{
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"createNewNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
    
	if (!jsonResult) return 0;
	else             return jsonResult.data ? [(NSDecimalNumber*)jsonResult.data intValue] : 0;
}

-(int)createNoteStartIncomplete
{
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"createNewNoteStartIncomplete"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
	if (!jsonResult) return 0;
	else             return jsonResult.data ? [(NSDecimalNumber*)jsonResult.data intValue] : 0;
}

-(void) contentAddedToNoteWithText:(JSONResult *)result
{
    if([self validObjectForKey:@"noteId" inDictionary:result.userInfo])
        [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:[self validIntForKey:@"noteId"      inDictionary:result.userInfo]
                                                              andFileURL:[self validObjectForKey:@"localURL" inDictionary:result.userInfo]];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
    if([self validObjectForKey:@"noteId" inDictionary:result.userInfo])
        [self fetchNote:[self validIntForKey:@"noteId" inDictionary:result.userInfo]];
}

-(void) addContentToNoteWithText:(NSString *)text type:(NSString *) type mediaId:(int) mediaId andNoteId:(int)noteId andFileURL:(NSURL *)fileURL
{
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",noteId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",mediaId],
                          type,
						  text,
						  nil];
    
    NSMutableDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:noteId], @"noteId", fileURL, @"localURL", nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addContentToNote"
                                                              andArguments:arguments
                                                               andUserInfo:userInfo];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(contentAddedToNoteWithText:)];
}

-(void)deleteNoteContentWithContentId:(int)contentId andNoteId:(int) noteId
{
    if(contentId != -1)
    {
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",contentId],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"notes"
                                                                 andMethodName:@"deleteNoteContent"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt: noteId],@"noteId", nil];
        [jsonConnection performAsynchronousRequestWithHandler:@selector(sendNotificationToNoteViewer:) andUserInfo:userInfo];
    }
}

-(void)deleteNoteLocationWithNoteId:(int)noteId
{
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          @"PlayerNote",
						  [NSString stringWithFormat:@"%d",noteId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"locations"
                                                             andMethodName:@"deleteLocationsForObject"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(void)deleteNoteWithNoteId:(int)noteId
{
    if(noteId != 0)
    {
        NSArray *arguments = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"%d",noteId],
                              nil];
        JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                                andServiceName:@"notes"
                                                                 andMethodName:@"deleteNote"
                                                                  andArguments:arguments
                                                                   andUserInfo:nil];
        
        [jsonConnection performAsynchronousRequestWithHandler:@selector(sendNotificationToNotebookViewer)];
    }
}

-(void)sendNotificationToNoteViewer:(NSDictionary *)userInfo
{
    NSLog(@"NSNotification: NewContentListReady");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewContentListReady" object:nil userInfo:userInfo]];
}

-(void)sendNotificationToNotebookViewer
{
    NSLog(@"NSNotification: NoteDeleted");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NoteDeleted" object:nil]];
}

-(void) uploadContentToNoteWithFileURL:(NSURL *)fileURL name:(NSString *)name noteId:(int) noteId type: (NSString *)type{
    ARISUploader *uploader = [[ARISUploader alloc]initWithURLToUpload:fileURL gameSpecific:YES delegate:self doneSelector:@selector(noteContentUploadDidfinish: ) errorSelector:@selector(uploadNoteContentDidFail:)];
    NSNumber *nId = [[NSNumber alloc]initWithInt:noteId];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:4];
    [userInfo setValue:name forKey:@"title"];
    [userInfo setValue:nId forKey:@"noteId"];
    [userInfo setValue:type forKey: @"type"];
    [userInfo setValue:fileURL forKey:@"url"];
	[uploader setUserInfo:userInfo];
	
	NSLog(@"Model: Uploading File. gameID:%d title:%@ noteId:%d",[AppModel sharedAppModel].currentGame.gameId,name,noteId);
	
	//ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[[[RootViewController sharedRootViewController] showWaitingIndicator:@"Uploading" displayProgressBar:YES];
	//[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
    
	[uploader upload];
}

- (void)noteContentUploadDidfinish:(ARISUploader*)uploader {
	NSLog(@"Model: Upload Note Content Request Finished. Response: %@", [uploader responseString]);
	
    int noteId = [self validObjectForKey:@"noteId" inDictionary:[uploader userInfo]] ? [self validIntForKey:@"noteId" inDictionary:[uploader userInfo]] : 0;
    NSString *title = [self validObjectForKey:@"title" inDictionary:[uploader userInfo]];
    NSString *type = [self validObjectForKey:@"type" inDictionary:[uploader userInfo]];
    NSURL *localUrl = [self validObjectForKey:@"url" inDictionary:[uploader userInfo]];
    NSString *newFileName = [uploader responseString];
    
    //TODO: Check that the response string is actually a new filename that was made on the server, not an error
#warning Don't know use of this
    /*
     NoteContent *newContent = [[NoteContent alloc] init];
     newContent.noteId = noteId;
     newContent.title = @"Refreshing From Server...";
     newContent.type = type;
     newContent.contentId = 0;
     
     [[[[[AppModel sharedAppModel] gameNoteList] objectForKey:[NSNumber numberWithInt:noteId]] contents] addObject:newContent]; */
    [[AppModel sharedAppModel].uploadManager deleteContentFromNoteId:noteId andFileURL:localUrl];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
    
    //Call server service
    NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          [NSString stringWithFormat:@"%d",noteId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          newFileName,
                          type,
                          title,
                          nil];
    JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addContentToNoteFromFileName"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt: noteId],@"noteId", nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(updateNoteAfterRequest:) andUserInfo:userInfo];
}

- (void) updateNoteAfterRequest:(NSMutableDictionary *) userInfo
{
    int noteId = [[userInfo objectForKey:@"noteId"] intValue];
    [self fetchNote:noteId];
}

- (void)uploadNoteContentDidFail:(ARISUploader *)uploader {
    NSError *error = uploader.error;
	NSLog(@"Model: uploadRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"UploadFailedKey", @"") message: NSLocalizedString(@"AppServicesUploadFailedMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
	
	[alert show];
    
    NSNumber *nId = [[NSNumber alloc]init];
    nId = [self validObjectForKey:@"noteId" inDictionary:[uploader userInfo]];
	//if (description == NULL) description = @"filename";
    
    [[AppModel sharedAppModel].uploadManager contentFailedUploading];
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:nId,@"noteId", nil];
    [self sendNotificationToNoteViewer:userInfo];
}

- (void)playerPicUploadDidfinish:(ARISUploader*)uploader {
	NSLog(@"Model: Upload Note Content Request Finished. Response: %@", [uploader responseString]);
    
    //Call server service
    
    NSString *newFileName = [uploader responseString];
    
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  newFileName,
                          nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"players"
                                                             andMethodName:@"addPlayerPicFromFilename"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseNewPlayerMediaResponseFromJSON:)];
    [[AppModel sharedAppModel].uploadManager contentFinishedUploading];
}

-(void)parseNewPlayerMediaResponseFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: parseNewPlayerMediaResponseFromJSON");
	
	//[[RootViewController sharedRootViewController] removeWaitingIndicator];
    
    if (jsonResult.data && [self validObjectForKey:@"media_id" inDictionary:((NSDictionary *)jsonResult.data)])
    {
        [AppModel sharedAppModel].playerMediaId = [self validIntForKey:@"media_id" inDictionary:((NSDictionary*)jsonResult.data)];
        [[AppModel sharedAppModel] saveUserDefaults];
    }
}


- (void)playerPicUploadDidFail:(ARISUploader *)uploader {
    NSError *error = uploader.error;
	NSLog(@"Model: uploadRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"UploadFailedKey", @"") message: NSLocalizedString(@"AppServicesUploadFailedMessageKey", @"") delegate: self cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles: nil];
	
	[alert show];
    
    [[AppModel sharedAppModel].uploadManager contentFailedUploading];
}

-(void)updateNoteWithNoteId:(int)noteId title:(NSString *)title publicToMap:(BOOL)publicToMap publicToList:(BOOL)publicToList{
    NSLog(@"Model: Updating Note with ID: %d andTitle: %@ andPublicToMap:%d andPublicToList: %d",noteId,title,publicToMap,publicToList);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",noteId],
						  title,
                          [NSString stringWithFormat:@"%d",publicToMap],
                          [NSString stringWithFormat:@"%d",publicToList],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateNote"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
    
}

- (void)updateNoteContent:(int)contentId title:(NSString *)text;
{
    NSLog(@"Model: Updating Note Content Title");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",contentId],
						  text,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateContentTitle"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

-(void)updateNoteContent:(int)contentId text:(NSString *)text{
    NSLog(@"Model: Updating Note Text Content");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",contentId],
						  text,
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"updateContent"
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:nil]; //This is a cheat to make sure that the fetch Happens After
}

- (void)updateServerWithPlayerLocation
{
#warning necessary?
 	if ([AppModel sharedAppModel].playerId == 0)
    {
        NSLog(@"Skipping Request: player not logged in");
		return;
	}
	
	if (currentlyUpdatingServerWithPlayerLocation) {
        NSLog(@"Skipping Request: already updating player location");
        return;
    }
    
    currentlyUpdatingServerWithPlayerLocation = YES;
    
	//Update the server with the new Player Location
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
						  [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName:@"players"
                                                              andMethodName:@"updatePlayerLocation"
                                                               andArguments:arguments
                                                                andUserInfo:nil];
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseUpdateServerWithPlayerLocationFromJSON:)];
}

#pragma mark Sync Fetch selectors
- (id) fetchFromService:(NSString *)aService usingMethod:(NSString *)aMethod withArgs:(NSArray *)arguments usingParser:(SEL)aSelector
{
	NSLog(@"JSON://%@/%@/%@", aService, aMethod, arguments);
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:aService
                                                             andMethodName:aMethod
                                                              andArguments:arguments
                                                               andUserInfo:nil];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest];
	
	if (!jsonResult)
    {
		NSLog(@"\tFailed.");
		return nil;
	}
	
	return [self performSelector:aSelector withObject:jsonResult.data];
}

-(void) fetchNote:(int)noteId
{
    if(!shouldIgnoreResults)
    {
        NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId], nil];
        Note *note= [self fetchFromService:@"notes" usingMethod:@"getNoteById" withArgs:arguments usingParser:@selector(parseNoteFromDictionary:)];
        [[InnovNoteModel sharedNoteModel] updateNote: note];
    }
}

#pragma mark ASync Fetch selectors

-(void) fetch:(int) noteCount moreTopNotesStartingFrom:     (int) lastLocation
{
    [self fetch:noteCount NotesWithMethod:@"getNextSetOfTopNotesForGame" StartingFrom:lastLocation];
}

-(void) fetch:(int) noteCount morePopularNotesStartingFrom: (int) lastLocation
{
    [self fetch:noteCount NotesWithMethod:@"getNextSetOfPopularNotesForGame" StartingFrom:lastLocation];
}

-(void) fetch:(int) noteCount moreRecentNotesStartingFrom: (int) lastLocation
{
    [self fetch:noteCount NotesWithMethod:@"getNextSetOfRecentNotesForGame" StartingFrom:lastLocation];
}

-(void) fetch:(int) noteCount morePlayerNotesStartingFrom:  (int) lastLocation
{
    [self fetch:noteCount NotesWithMethod:@"getNextSetOfPlayerNotesForGame" StartingFrom:lastLocation];
}


- (void)fetch:(int) noteCount NotesWithMethod:(NSString *) method StartingFrom: (int) lastLocation
{
    isCurrentlyFetchingGameNoteList = YES;
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],
                          [NSString stringWithFormat:@"%d",lastLocation],
                          [NSString stringWithFormat:@"%d",noteCount],nil];
    if([method isEqualToString:@"getNextSetOfPlayerNotesForGame"]) [arguments addObject: [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId]];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:method
                                                              andArguments:arguments
                                                               andUserInfo:nil];
    
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameNoteListFromJSON:)];
}

- (void) fetchMedia:(int)mediaId
{
    NSArray *arguments = [NSArray arrayWithObjects:
                          (([AppModel sharedAppModel].currentGame.gameId != 0) ? [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId] : @"player"),
                          [NSString stringWithFormat:@"%d",mediaId],
                          nil];
    
    JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"media"
                                                             andMethodName:@"getMediaObject"
                                                              andArguments:arguments andUserInfo:nil];
    
    [jsonConnection performAsynchronousRequestWithHandler:@selector(parseSingleMediaFromJSON:)];
}

- (void)fetchGameMediaListAsynchronously:(BOOL)YesForAsyncOrNoForSync
{
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
    
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"media"
                                                             andMethodName:@"getMedia"
                                                              andArguments:arguments andUserInfo:nil];
	
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameMediaListFromJSON:)];
	}
	else [self parseGameMediaListFromJSON: [jsonConnection performSynchronousRequest]];
}

- (void)fetchGameNoteTagsAsynchronously:(BOOL)YesForAsyncOrNoForSync
{
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"getAllTagsInGame"
                                                              andArguments:arguments andUserInfo:nil];
    
    if(YesForAsyncOrNoForSync)
        [jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameTagsListFromJSON:)];
	else
    {
        JSONResult *result = [jsonConnection performSynchronousRequest];
        [self parseGameTagsListFromJSON: result];
    }
}

-(void)parseGameTagsListFromJSON:(JSONResult *)jsonResult
{
    NSLog(@"AppModel: parseGameTagListFromJSON Beginning");
    
    NSArray *gameTagsArray = (NSArray *)jsonResult.data;
	
	NSMutableArray *tempTagsList = [[NSMutableArray alloc] initWithCapacity:10];
	
	NSEnumerator *gameTagEnumerator = [gameTagsArray objectEnumerator];
	NSDictionary *tagDictionary;
	while ((tagDictionary = [gameTagEnumerator nextObject]))
    {
        Tag *t = [[Tag alloc]init];
        t.tagName = [self validObjectForKey:@"tag" inDictionary:tagDictionary];
        t.playerCreated = [self validBoolForKey:@"player_created" inDictionary:tagDictionary];
        t.tagId = [self validIntForKey:@"tag_id" inDictionary:tagDictionary];
		[tempTagsList addObject:t];
	}
    
    NSDictionary *tags  = [[NSDictionary alloc] initWithObjectsAndKeys:tempTagsList,@"tags", nil];
    
    NSLog(@"NSNotification: NewTagListReady");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewTagListReady" object:nil userInfo:tags]];
}

-(void)addTagToNote:(int)noteId tagName:(NSString *)tag
{
    NSLog(@"AppModel: Adding Tag to note");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",[AppModel sharedAppModel].currentGame.gameId],tag, nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"addTagToNote"
                                                              andArguments:arguments andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil];
}

-(void)deleteTagFromNote:(int)noteId tagId:(int)tagId{
    NSLog(@"AppModel: Deleting tag from note");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",noteId],[NSString stringWithFormat:@"%d",tagId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"notes"
                                                             andMethodName:@"deleteTagFromNote"
                                                              andArguments:arguments andUserInfo:nil];
    [jsonConnection performAsynchronousRequestWithHandler:nil];
    
}

- (void)fetchOneGameGameList:(int)gameId
{
    if (currentlyFetchingOneGame)
    {
        NSLog(@"Skipping Request: already fetching one game");
        return;
    }
    
    currentlyFetchingOneGame = YES;
    
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
                          [NSString stringWithFormat:@"%d",gameId],
                          [NSString stringWithFormat:@"%d",[AppModel sharedAppModel].playerId],
                          [NSString stringWithFormat:@"%d",1],
                          [NSString stringWithFormat:@"%d",999999999],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",[AppModel sharedAppModel].playerLocation.coordinate.longitude],
                          [NSString stringWithFormat:@"%d",1],//'showGamesInDev' = 1, because if you're specifically seeking out one game, who cares
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:[AppModel sharedAppModel].serverURL
                                                            andServiceName:@"games"
                                                             andMethodName:@"getOneGame"
                                                              andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseOneGameGameListFromJSON:)];
}

#pragma mark Parsers
- (BOOL) validBoolForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(boolValue)] ? [theObject boolValue] : kEmptyBoolValue;
}

- (NSInteger) validIntForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(intValue)] ? [theObject intValue] : kEmptyIntValue;
}

- (float) validFloatForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(floatValue)] ? [theObject floatValue] : kEmptyFloatValue;
}

- (double) validDoubleForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(doubleValue)] ? [theObject doubleValue] : kEmptyDoubleValue;
}

- (id) validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return (theObject == [NSNull null]) ? nil : theObject;
}

- (NSString *) validStringForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary
{
    id theObject = [aDictionary valueForKey:aKey];
    return ([theObject respondsToSelector:@selector(isEqualToString:)]) ? theObject : @"";
}

-(Note *)parseNoteFromDictionary: (NSDictionary *)noteDictionary
{
	Note *aNote = [[Note alloc] init];
    aNote.dropped          = [self validBoolForKey:@"dropped"            inDictionary:noteDictionary];
    aNote.showOnMap        = [self validBoolForKey:@"public_to_map"      inDictionary:noteDictionary];
    aNote.showOnList       = [self validBoolForKey:@"public_to_notebook" inDictionary:noteDictionary];
    aNote.userLiked        = [self validBoolForKey:@"player_liked"       inDictionary:noteDictionary];
    aNote.userFlagged      = [self validBoolForKey:@"player_flagged"     inDictionary:noteDictionary];
    aNote.noteId           = [self validIntForKey:@"note_id"             inDictionary:noteDictionary];
    aNote.parentNoteId     = [self validIntForKey:@"parent_note_id"      inDictionary:noteDictionary];
    aNote.parentRating     = [self validIntForKey:@"parent_rating"       inDictionary:noteDictionary];
    aNote.numRatings       = [self validIntForKey:@"likes"               inDictionary:noteDictionary];
    aNote.creatorId        = [self validIntForKey:@"owner_id"            inDictionary:noteDictionary];
    aNote.latitude         = [self validDoubleForKey:@"lat"              inDictionary:noteDictionary];
    aNote.longitude        = [self validDoubleForKey:@"lon"              inDictionary:noteDictionary];
    aNote.username         = [self validObjectForKey:@"username"         inDictionary:noteDictionary];
    aNote.displayname      = [self validStringForKey:@"displayname"      inDictionary:noteDictionary];
    aNote.title            = [self validObjectForKey:@"title"            inDictionary:noteDictionary];
    aNote.facebookShareCount   = [self validIntForKey:@"facebook_shares" inDictionary:noteDictionary];
    aNote.twitterShareCount     = [self validIntForKey:@"twitter_shares" inDictionary:noteDictionary];
    aNote.pinterestShareCount = [self validIntForKey:@"pinterest_shares" inDictionary:noteDictionary];
    aNote.emailShareCount         = [self validIntForKey:@"email_shares" inDictionary:noteDictionary];
    
    NSArray *contents = [self validObjectForKey:@"contents" inDictionary:noteDictionary];
    for (NSDictionary *content in contents)
    {
        NoteContent *c = [[NoteContent alloc] init];
        c.text      = [self validObjectForKey:@"text"    inDictionary:content];
        c.title     = [self validObjectForKey:@"title"   inDictionary:content];
        c.type      = [self validObjectForKey:@"type"    inDictionary:content];
        c.contentId = [self validIntForKey:@"content_id" inDictionary:content];
        c.mediaId   = [self validIntForKey:@"media_id"   inDictionary:content];
        c.noteId    = [self validIntForKey:@"note_id"    inDictionary:content];
        c.sortIndex = [self validIntForKey:@"sort_index" inDictionary:content];
        int returnCode = [self validIntForKey:@"returnCode" inDictionary:[self validObjectForKey:@"media" inDictionary:content]];
        NSDictionary *m = [self validObjectForKey:@"data" inDictionary:[self validObjectForKey:@"media" inDictionary:content]];
        if(returnCode == 0 && m)
        {
            Media *media = [[AppModel sharedAppModel].mediaCache mediaForMediaId:c.mediaId];
            NSString *fileName = [self validObjectForKey:@"file_path" inDictionary:m];
            if(fileName == nil) fileName = [self validObjectForKey:@"file_name" inDictionary:m];
            NSString *urlPath = [self validObjectForKey:@"url_path" inDictionary:m];
            NSString *fullUrl = [NSString stringWithFormat:@"%@%@", urlPath, fileName];
            media.url = fullUrl;
            media.type = [self validObjectForKey:@"type" inDictionary:m];
        }
        
        [aNote.contents addObject:c];
    }
    
    NSArray *tags = [self validObjectForKey:@"tags" inDictionary:noteDictionary];
    for (NSDictionary *tagOb in tags)
    {
        Tag *tag = [[Tag alloc] init];
        tag.tagName       = [self validObjectForKey:@"tag"          inDictionary:tagOb];
        tag.playerCreated = [self validBoolForKey:@"player_created" inDictionary:tagOb];
        tag.tagId         = [self validIntForKey:@"tag_id"          inDictionary:tagOb];
        [aNote.tags addObject:tag];
    }
    NSArray *comments = [self validObjectForKey:@"comments" inDictionary:noteDictionary];
    NSEnumerator *enumerator = [((NSArray *)comments) objectEnumerator];
	NSDictionary *dict;
    while ((dict = [enumerator nextObject]))
    {
        //This is returning an object with playerId,tex, and rating. Right now, we just want the text
        //TODO: Create a Comments object
        Note *c = [self parseNoteFromDictionary:dict];
        [aNote.comments addObject:c];
    }
    
	NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"noteId"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    aNote.comments = [[aNote.comments sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
	return aNote;
}

-(void)parseGameNoteListFromJSON: (JSONResult *)jsonResult
{
    if(!shouldIgnoreResults){
        NSArray *noteListArray = (NSArray *)jsonResult.data;
        NSLog(@"NSNotification: ReceivedNoteList");
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedNoteList"      object:nil]];
        NSMutableDictionary *tempNoteList = [[NSMutableDictionary alloc] init];
        
        NSEnumerator *enumerator = [((NSArray *)noteListArray) objectEnumerator];
        NSDictionary *dict;
        while ((dict = [enumerator nextObject])) {
            Note *tmpNote = [self parseNoteFromDictionary:dict];
            [tempNoteList setObject:tmpNote forKey:[NSNumber numberWithInt:tmpNote.noteId]];
        }
        
        NSDictionary *notes  = [[NSDictionary alloc] initWithObjectsAndKeys:tempNoteList,@"notes", nil];
        
        NSLog(@"NSNotification: NewNoteListReady");
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewNoteListReady"      object:nil userInfo:notes]];
    }
    isCurrentlyFetchingGameNoteList = NO;
}

-(void)parseLoginResponseFromJSON:(JSONResult *)jsonResult
{
	NSLog(@"AppServices: parseLoginResponseFromJSON");
	
    //	[[RootViewController sharedRootViewController] removeWaitingIndicator];
    
	if (jsonResult.data != [NSNull null])
    {
		[AppModel sharedAppModel].playerId = [self validIntForKey:@"player_id" inDictionary:((NSDictionary*)jsonResult.data)];
		[AppModel sharedAppModel].playerMediaId = [self validIntForKey:@"media_id" inDictionary:((NSDictionary*)jsonResult.data)];
        [AppModel sharedAppModel].userName = [self validObjectForKey:@"user_name" inDictionary:((NSDictionary*)jsonResult.data)];
        [AppModel sharedAppModel].displayName = [self validObjectForKey:@"display_name" inDictionary:((NSDictionary*)jsonResult.data) ];
        [[AppModel sharedAppModel] saveUserDefaults];
        
        //Subscribe to player channel
        //[RootViewController sharedRootViewController].playerChannel = [[RootViewController sharedRootViewController].client subscribeToPrivateChannelNamed:[NSString stringWithFormat:@"%d-player-channel",[AppModel sharedAppModel].playerId]];
    }
	else
        [AppModel sharedAppModel].playerId = 0;
    
    NSLog(@"NSNotification: NewLoginResponseReady");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLoginResponseReady" object:nil]];
}

-(void)parseSelfRegistrationResponseFromJSON: (JSONResult *)jsonResult
{
	if (!jsonResult)
    {
        NSLog(@"NSNotification: SelfRegistrationFailed");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}
    
    int newId = [(NSDecimalNumber*)jsonResult.data intValue];
    
	if (newId > 0)
    {
        NSLog(@"NSNotification: SelfRegistrationSucceeded");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationSucceeded" object:nil]];
	}
	else
    {
        NSLog(@"NSNotification: SelfRegistrationFailed");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}
}

- (Game *)parseGame:(NSDictionary *)gameSource
{
    Game *game = [[Game alloc] init];
    
    game.gameId                   = [self validIntForKey:@"game_id"               inDictionary:gameSource];
    game.hasBeenPlayed            = [self validBoolForKey:@"has_been_played"      inDictionary:gameSource];
    game.isLocational             = [self validBoolForKey:@"is_locational"        inDictionary:gameSource];
    game.showPlayerLocation       = [self validBoolForKey:@"show_player_location" inDictionary:gameSource];
    game.rating                   = [self validIntForKey:@"rating"                inDictionary:gameSource];
    game.pcMediaId                = [self validIntForKey:@"pc_media_id"           inDictionary:gameSource];
    game.numPlayers               = [self validIntForKey:@"numPlayers"            inDictionary:gameSource];
    game.playerCount              = [self validIntForKey:@"count"                 inDictionary:gameSource];
    game.gdescription             = [self validStringForKey:@"description"        inDictionary:gameSource];
    game.name                     = [self validStringForKey:@"name"               inDictionary:gameSource];
    game.authors                  = [self validStringForKey:@"editors"            inDictionary:gameSource];
    game.mapType                  = [self validObjectForKey:@"map_type"           inDictionary:gameSource];
    if (!game.mapType || (![game.mapType isEqualToString:@"STREET"] && ![game.mapType isEqualToString:@"SATELLITE"] && ![game.mapType isEqualToString:@"HYBRID"])) game.mapType = @"STREET";
    
    NSString *distance = [self validObjectForKey:@"distance" inDictionary:gameSource];
    if (distance) game.distanceFromPlayer = [distance doubleValue];
    else game.distanceFromPlayer = 999999999;
    
    NSString *latitude  = [self validObjectForKey:@"latitude" inDictionary:gameSource];
    NSString *longitude = [self validObjectForKey:@"longitude" inDictionary:gameSource];
    if (latitude && longitude)
        game.location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    else
        game.location = [[CLLocation alloc] init];
    
    
    
    
    int iconMediaId;
    if((iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:gameSource]) > 0)
    {
        game.iconMedia = [[AppModel sharedAppModel] mediaForMediaId:iconMediaId];
        game.iconMediaUrl = [NSURL URLWithString:game.iconMedia.url];
    }
    NSString *iconMediaUrl;
    if(!game.iconMedia && (iconMediaUrl = [self validObjectForKey:@"icon_media_url" inDictionary:gameSource]) && [iconMediaUrl length]>0)
    {
        game.iconMediaUrl = [NSURL URLWithString:iconMediaUrl];
        game.iconMedia = [[AppModel sharedAppModel].mediaCache mediaForUrl:game.iconMediaUrl];
    }
    
    int mediaId;
    if((mediaId = [self validIntForKey:@"media_id" inDictionary:gameSource]) > 0)
    {
        game.splashMedia = [[AppModel sharedAppModel] mediaForMediaId:mediaId];
        game.mediaUrl = [NSURL URLWithString:game.splashMedia.url];
    }
    NSString *mediaUrl;
    if (!game.splashMedia && (mediaUrl = [self validObjectForKey:@"media_url" inDictionary:gameSource]) && [mediaUrl length]>0)
    {
        game.mediaUrl = [NSURL URLWithString:mediaUrl];
        game.splashMedia = [[AppModel sharedAppModel].mediaCache mediaForUrl:game.mediaUrl];
    }
    
    game.launchNodeId                  = [self validIntForKey:@"on_launch_node_id"         inDictionary:gameSource];
    game.completeNodeId                = [self validIntForKey:@"game_complete_node_id"     inDictionary:gameSource];
    game.calculatedScore               = [self validIntForKey:@"calculatedScore"           inDictionary:gameSource];
    game.numReviews                    = [self validIntForKey:@"numComments"               inDictionary:gameSource];
    game.allowsPlayerTags              = [self validBoolForKey:@"allow_player_tags"        inDictionary:gameSource];
    game.allowShareNoteToMap           = [self validBoolForKey:@"allow_share_note_to_map"  inDictionary:gameSource];
    game.allowShareNoteToList          = [self validBoolForKey:@"allow_share_note_to_book" inDictionary:gameSource];
    game.allowNoteComments             = [self validBoolForKey:@"allow_note_comments"      inDictionary:gameSource];
    game.allowNoteLikes                = [self validBoolForKey:@"allow_note_likes"         inDictionary:gameSource];
    game.allowTrading                  = [self validBoolForKey:@"allow_trading"            inDictionary:gameSource];
    
    NSArray *comments = [self validObjectForKey:@"comments" inDictionary:gameSource];
    for (NSDictionary *comment in comments) {
        //This is returning an object with playerId,tex, and rating. Right now, we just want the text
        //TODO: Create a Comments object
        Comment *c = [[Comment alloc] init];
        c.text = [self validObjectForKey:@"text" inDictionary:comment];
        c.playerName = [self validObjectForKey:@"username" inDictionary:comment];
        NSString *cRating = [self validObjectForKey:@"rating" inDictionary:comment];
        if (cRating) c.rating = [cRating intValue];
        [game.comments addObject:c];
    }
    
    //NSLog(@"Model: Adding Game: %@", game.name);
    return game;
}

-(NSMutableArray *)parseGameListFromJSON:(JSONResult *)jsonResult
{
    NSArray *gameListArray = (NSArray *)jsonResult.data;
    
    NSMutableArray *tempGameList = [[NSMutableArray alloc] init];
    
    NSEnumerator *gameListEnumerator = [gameListArray objectEnumerator];
    NSDictionary *gameDictionary;
    while ((gameDictionary = [gameListEnumerator nextObject])) {
        [tempGameList addObject:[self parseGame:(gameDictionary)]];
    }
    
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error])
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    
    return tempGameList;
}

-(void)parseOneGameGameListFromJSON: (JSONResult *)jsonResult
{
    currentlyFetchingOneGame = NO;
    [AppModel sharedAppModel].oneGameGameList = [self parseGameListFromJSON:jsonResult];
    Game * game = (Game *)[[AppModel sharedAppModel].oneGameGameList  objectAtIndex:0];
    NSLog(@"NSNotification: NewOneGameGameListReady");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewOneGameGameListReady" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:game,@"game", nil]]];
}

- (void)saveGameComment:(NSString*)comment game:(int)gameId starRating:(int)rating
{
	NSLog(@"AppModel: Save Comment Requested");
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", [AppModel sharedAppModel].playerId], [NSString stringWithFormat:@"%d", gameId], [NSString stringWithFormat:@"%d", rating], comment, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:[AppModel sharedAppModel].serverURL
                                                             andServiceName: @"games"
                                                              andMethodName:@"saveComment"
                                                               andArguments:arguments andUserInfo:nil];
	
	[jsonConnection performAsynchronousRequestWithHandler:@selector(parseGameCommentResponseFromJSON:)];
}

-(void)parseSingleMediaFromJSON: (JSONResult *)jsonResult
{
    //Just convert the data into a dictionary and pretend it is a full game list, so same thing as 'parseGameMediaListFromJSON'
    NSArray * data = [[NSArray alloc] initWithObjects:jsonResult.data, nil];
    jsonResult.data = data;
    [self performSelector:@selector(startCachingMedia:) withObject:jsonResult afterDelay:.1];
}

-(void)parseGameMediaListFromJSON: (JSONResult *)jsonResult
{
    NSLog(@"NSNotification: GamePieceReceived");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GamePieceReceived" object:nil]];
    [self performSelector:@selector(startCachingMedia:) withObject:jsonResult afterDelay:.1];
}

-(void)startCachingMedia:(JSONResult *)jsonResult
{
    NSArray *serverMediaArray = (NSArray *)jsonResult.data;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(gameid = 0) OR (gameid = %d)", [AppModel sharedAppModel].currentGame.gameId];
    NSArray *currentlyCachedMediaArray = [[AppModel sharedAppModel].mediaCache mediaForPredicate:predicate];
    NSLog(@"%d total media for %d",[currentlyCachedMediaArray count], [AppModel sharedAppModel].currentGame.gameId);
    
    //Construct cached media map (dictionary with identical key/values of mediaId) to quickly check for existence of media
    NSMutableDictionary *currentlyCachedMediaMap = [[NSMutableDictionary alloc]initWithCapacity:currentlyCachedMediaArray.count];
    for(int i = 0; i < [currentlyCachedMediaArray count]; i++)
    {
        if([[currentlyCachedMediaArray objectAtIndex:i] uid])
            [currentlyCachedMediaMap setObject:[currentlyCachedMediaArray objectAtIndex:i] forKey:[[currentlyCachedMediaArray objectAtIndex:i] uid]];
        else
            NSLog(@"found broken coredata entry");
    }
    
    Media *tmpMedia;
    for(int i = 0; i < [serverMediaArray count]; i++)
    {
        NSDictionary *serverMediaDict = [serverMediaArray objectAtIndex:i];
        int mediaId        = [self validIntForKey:@"media_id"     inDictionary:serverMediaDict];
        NSString *fileName = [self validObjectForKey:@"file_path" inDictionary:serverMediaDict];
        
        if(!(tmpMedia = [currentlyCachedMediaMap objectForKey:[NSNumber numberWithInt:mediaId]]))
            tmpMedia = [[AppModel sharedAppModel].mediaCache addMediaToCache:mediaId];
        
        if(tmpMedia && (tmpMedia.url == nil || tmpMedia.type == nil || tmpMedia.gameid == nil))
        {
            tmpMedia.url = [NSString stringWithFormat:@"%@%@", [self validObjectForKey:@"url_path" inDictionary:serverMediaDict], fileName];
            tmpMedia.type = [self validObjectForKey:@"type" inDictionary:serverMediaDict];
            tmpMedia.gameid = [NSNumber numberWithInt:[self validIntForKey:@"game_id" inDictionary:serverMediaDict]];
            NSLog(@"Cached Media: %d with URL: %@",mediaId,tmpMedia.url);
        }
    }
    NSError *error;
    if (![[AppModel sharedAppModel].mediaCache.context save:&error])
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    
    NSLog(@"NSNotification: ReceivedMediaList");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedMediaList" object:nil]];
    NSLog(@"NSNotification: GamePieceReceived");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"GamePieceReceived" object:nil]];
}

-(void)parseUpdateServerWithPlayerLocationFromJSON:(JSONResult *)jsonResult
{
    currentlyUpdatingServerWithPlayerLocation = NO;
}

@end