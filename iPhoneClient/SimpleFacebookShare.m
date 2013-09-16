//
//  SimpleFacebookShare.m
//  simple-share
//
//  Created by  on 30.05.12.
//  Copyright 2012 Felix Schulze. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "SimpleFacebookShare.h"

#import "AppServices.h"
#import "SVProgressHUD.h"
#import "ViewControllerHelper.h"
#import "Logger.h"

#import "AppModel.h"
#import "SifterAppDelegate.h"
#import "Note.h"
#import "Tag.h"

#define ACCESS_TOKEN_KEY    @"AccessToken"
#define EXPIRATION_DATE_KEY @"ExpDate"

@interface SimpleFacebookShare()
{
    NSString *appActionLink;
}

@end

@implementation SimpleFacebookShare

- (id)initWithAppName:(NSString *)theAppName appUrl:(NSString *)theAppUrl {
    self = [super init];
    if (self) {
        NSArray *actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:theAppName, @"name", theAppUrl, @"link", nil], nil];
        NSError *error = nil;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:actionLinks options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        appActionLink = jsonString;
    }
    return self;
}

//NEW METHOD
- (void)shareNote:(Note *) note automatically:(BOOL) autoShare
{
    NSString *title = ([note.tags count] > 0) ? ((Tag *)[note.tags objectAtIndex:0]).tagName : DEFAULT_TITLE;
    NSString *imageURL = [[AppModel sharedAppModel] mediaForMediaId:note.imageMediaId].url;
#warning fix url to be web notebook url
    NSString *urlString  = HOME_URL;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: imageURL, @"picture", title, @"name", note.text, @"description", note.text, @"message", urlString, @"link", nil];
    NSDictionary *completionParams = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:note.noteId] forKey:@"noteId"];
    [self _shareInitalParams:params completionParams:completionParams automatically:autoShare];
}

- (void)_shareInitalParams:(NSDictionary *)params completionParams:(NSDictionary *) completionParams automatically: (BOOL) autoShare {
    if (!(FBSession.activeSession.isOpen))
        [self openSession];
    
    [self _shareAndReauthorize:params completionParams:completionParams automatically: autoShare];
}

- (void) openSession
{
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded)
    {
        [FBSession.activeSession openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error)
         {
             if(error)
             {
                 [[Logger sharedLogger] logError:error];
                 [SVProgressHUD showErrorWithStatus:@"Authorization Error."];
             }
         }];
    }
    else {
        [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (error)
            {
                [[Logger sharedLogger] logError:error];
                [SVProgressHUD showErrorWithStatus:@"Authorization Error."];
            }
        }];
    }
}

- (void)_shareAndReauthorize:(NSDictionary *)params completionParams:(NSDictionary *) completionParams automatically: (BOOL) autoShare
{
    __weak SimpleFacebookShare *selfForBlock = self;
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)
    {
        [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error)
         {
             if (error)
             {
                 [[Logger sharedLogger] logError:error];
                 [SVProgressHUD showErrorWithStatus:@"Authorization Error"];
             }
             else
                 [selfForBlock _shareParams:params completionParams:completionParams automatically: autoShare];
             
         }];
    }
    else
        [self _shareParams:params completionParams: completionParams automatically: autoShare];
}

//MODIFIED METHOD
- (void)_shareParams:(NSDictionary *)params completionParams:(NSDictionary *) completionParams automatically: (BOOL) autoShare {
    if(!autoShare)
    {
        __weak SimpleFacebookShare *selfForBlock = self;
        [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error)
         {
             if (error)
             {
                 [[Logger sharedLogger] logError:error];
                 [SVProgressHUD showErrorWithStatus:@"Saving Error."];
             }
             else {
                 NSDictionary *resultParams = [selfForBlock _parseURLParams:[resultURL query]];
                 if ([resultParams valueForKey:@"error_code"])
                 {
                     [SVProgressHUD showErrorWithStatus:@"An Error Has Occured."];
                     NSLog(@"Error: %@", [resultParams valueForKey:@"error_msg"]);
                 }
                 else if ([resultParams valueForKey:@"post_id"])
                 {
                     if(!autoShare)
                         [SVProgressHUD showSuccessWithStatus:@"Success"];
                     
                     NSNumber *noteIdNumber = [completionParams objectForKey:@"noteId"];
                     if(noteIdNumber)
                         [[AppServices sharedAppServices] sharedNoteToFacebook: [noteIdNumber intValue]];
                 }
             }
         }];
    }
    else
    {
        [FBRequestConnection startWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error)
                [[Logger sharedLogger] logError:error];
        }];
    }
}

- (void)getUsernameWithCompletionHandler:(void (^)(NSString *username, NSError *error))completionHandler {
    if (completionHandler)
    {
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded)
        {
            __weak SimpleFacebookShare *selfForBlock = self;
            [FBSession.activeSession openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error)
             {
                 [selfForBlock _getUserNameWithCompletionHandlerOnActiveSession:completionHandler];
                 
             }];
        }
    }
}

- (void)_getUserNameWithCompletionHandlerOnActiveSession:(void (^)(NSString *username, NSError *error))completionHandler {
    [FBRequestConnection startWithGraphPath:@"me"
                                 parameters:nil HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (error) {
                                  completionHandler(nil, error);
                              }
                              else {
                                  NSString *username = [result objectForKey:@"name"];
                                  completionHandler(username, nil);
                              }
                          }];
}

- (NSDictionary *) _parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

#pragma mark Login Button Delegate Methods

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    //log in to user, wait for user info
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    //should never get here
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user
{
    [[AppServices sharedAppServices] loginWithFacebookEmail:[user objectForKey:@"email"] displayName:user.name andId:[user objectForKey:@"id"]];
    // [((UINavigationController *)[ViewControllerHelper getCurrentRootViewController]) popToRootViewControllerAnimated:YES];
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    NSString *alertMessage, *alertTitle;
    if (error.fberrorShouldNotifyUser) {
        // If the SDK has a message for the user, surface it. This conveniently
        // handles cases like password change or iOS6 app slider state.
        alertTitle = @"Facebook Error";
        alertMessage = error.fberrorUserMessage;
    } else if (error.fberrorCategory == FBErrorCategoryAuthenticationReopenSession) {
        // It is important to handle session closures since they can happen
        // outside of the app. You can inspect the error for more context
        // but this sample generically notifies the user.
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
        // The user has cancelled a login. You can inspect the error
        // for more context. For this sample, we will simply ignore it.
        NSLog(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark Facebook Status

- (void)handleDidBecomeActive
{
    [FBSession.activeSession handleDidBecomeActive];
}

- (BOOL)handleOpenURL:(NSURL *)theUrl
{
    return [FBSession.activeSession handleOpenURL:theUrl];
}

- (BOOL)isLoggedIn
{
    FBSessionState state = FBSession.activeSession.state;
    if (state == FBSessionStateOpen || state == FBSessionStateCreatedTokenLoaded || state == FBSessionStateOpenTokenExtended)
        return YES;
    
    return NO;
}

- (void)logOut
{
    [FBSession.activeSession closeAndClearTokenInformation];
    
    //Delete data from User Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"FBAccessTokenInformationKey"];
    
    //Remove facebook Cookies:
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        if ([cookie.domain isEqualToString:@".facebook.com"] || [cookie.domain isEqualToString:@"facebook.com"]) {
            [storage deleteCookie:cookie];
            NSLog(@"Delete facebook cookie: %@", cookie);
        }
    }
    [defaults synchronize];
}

- (void)close
{
    [FBSession.activeSession close];
}

@end