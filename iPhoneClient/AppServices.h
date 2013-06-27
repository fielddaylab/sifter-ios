//
//  AppServices.h
//  ARIS
//
//  Created by David J Gagnon on 5/11/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "AppModel.h"
#import "MyCLController.h"
#import "Game.h"
#import "Media.h"
#import "JSONResult.h"
#import "JSONConnection.h"
#import "JSONResult.h"
#import "JSON.h"
#import "ARISAppDelegate.h"
#import "Comment.h"
#import "Note.h"
#import "NoteContent.h"
#import "Tag.h"
#import "ARISUploader.h"

@interface AppServices : NSObject

extern NSString *const kARISServerServicePackage;

@property(readwrite) BOOL isCurrentlyFetchingGameNoteList;

+ (AppServices *)sharedAppServices;

- (void)resetCurrentlyFetchingVars;

//Player
- (void)login;
- (void)registerNewUser:(NSString*)userName
               password:(NSString*)pass
			  firstName:(NSString*)firstName
               lastName:(NSString*)lastName
                  email:(NSString*)email;
- (void)createUserAndLoginWithGroup:(NSString *)groupName;
- (void)uploadPlayerPicMediaWithFileURL:(NSURL *)fileURL;
- (void)updatePlayer:(int)playerId withName:(NSString *)name andImage:(int)mid;
- (void)resetAndEmailNewPassword:(NSString *)email;
- (void)setShowPlayerOnMap;

- (void)fetchOneGameGameList:(int)gameId;

- (void)fetchTabBarItemsForGame:(int)gameId; //This should probably just be part of "fetchGame".

//Fetch Game Data (ONLY CALLED ONCE PER GAME!!)
- (void)fetchGameMediaListAsynchronously:    (BOOL)YesForAsyncOrNoForSync;
- (void)fetchGameNoteTagsAsynchronously:     (BOOL)YesForAsyncOrNoForSync;
- (void)fetchGameNoteListAsynchronously:     (BOOL)YesForAsyncOrNoForSync;

//Get Specific Data (technically, these being called is a sign that the "fetch game data" functions failed somewhere...)
- (void)fetchMedia:(int)mediaId;
- (Note *)fetchNote:(int)noteId;

-(void) fetch:(int) noteCount moreTopNotesStartingFrom:     (int) lastLocation;
-(void) fetch:(int) noteCount morePopularNotesStartingFrom: (int) lastLocation;
-(void) fetch:(int) noteCount moreRecentNotesStartingFrom:  (int) lastLocation;
-(void) fetch:(int) noteCount morePlayerNotesStartingFrom:  (int) lastLocation;

//Note Stuff
- (int)createNote;
- (int)createNoteStartIncomplete;
- (void)setNoteCompleteForNoteId:(int)noteId;
- (void)updateNoteWithNoteId:(int)noteId title:(NSString *)title publicToMap:(BOOL)publicToMap publicToList:(BOOL)publicToList;
- (void)deleteNoteWithNoteId:(int)noteId;
- (void)dropNote:(int)noteId atCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)addContentToNoteWithText:(NSString *)text type:(NSString *)type mediaId:(int)mediaId andNoteId:(int)noteId andFileURL:(NSURL *)fileURL;
- (void)uploadContentToNoteWithFileURL:(NSURL *)fileURL name:(NSString *)name noteId:(int)noteId type:(NSString *)type;
- (void)deleteNoteContentWithContentId:(int)contentId andNoteId:(int) noteId;
- (void)deleteNoteLocationWithNoteId:(int)noteId;
- (void)updateNoteContent:(int)contentId text:(NSString *)text;
- (void)updateNoteContent:(int)contentId title:(NSString *)title;
- (void)addTagToNote:(int)noteId tagName:(NSString *)tag;
- (void)deleteTagFromNote:(int)noteId tagId:(int)tagId;
- (int)addCommentToNoteWithId:(int)noteId andTitle:(NSString *)title;
- (void)updateCommentWithId:(int)noteId andTitle:(NSString *)title andRefresh:(BOOL)refresh;
- (void)likeNote:(int)noteId;
- (void)unLikeNote:(int)noteId;
- (void)checkIfNoteLiked:(int) noteId;

//Tell server of state
- (void)updateServerWithPlayerLocation;

//Parse server responses
- (NSMutableArray *)parseGameListFromJSON:(JSONResult *)jsonResult;
- (void)parseGameMediaListFromJSON:       (JSONResult *)jsonResult;
- (void)parseGameNoteListFromJSON:        (JSONResult *)jsonResult;
- (void)parseGameTagsListFromJSON:        (JSONResult *)jsonResult;

//Parse individual pieces of server response
- (Game *)     parseGameFromDictionary:     (NSDictionary *)gameSource;
- (Note *)     parseNoteFromDictionary:     (NSDictionary *)noteDictionary;

- (void)updateServerGameSelected;
- (void)fetchQRCode:(NSString*)QRcodeId;
- (void)saveGameComment:(NSString*)comment game:(int)gameId starRating:(int)rating;
- (void)sendNotificationToNoteViewer;
- (void)sendNotificationToNotebookViewer;
- (void)startOverGame:(int)gameId;

@end
