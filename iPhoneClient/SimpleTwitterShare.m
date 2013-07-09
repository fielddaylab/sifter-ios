//
//  SimpleTwitterShare.m
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

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SimpleTwitterShare.h"
#import "AppServices.h"
#import "ViewControllerHelper.h"
#import "SVProgressHUD.h"

#import "JSONResult.h"

#define TWEET_SIZE 140
#define URL_SIZE   22

@implementation SimpleTwitterShare {
    
}

- (BOOL) canSendTweet {
    Class socialClass = NSClassFromString(@"SLComposeViewController");
    if (socialClass != nil) {
        return YES;
    }
    Class tweeterClass = NSClassFromString(@"TWTweetComposeViewController");
    if (tweeterClass == nil) {
        return NO;
    }
    if ([TWTweetComposeViewController canSendTweet]) {
        return YES;
    }
    return NO;
}

- (void) shareText:(NSString *)text withImage:(UIImage *) image andURL:(NSString *) urlString fromNote:(int) noteId automatically: (BOOL) autoShare
{
    if ([self canSendTweet])
    {
        int characterCountRemaining = TWEET_SIZE;
        if(!autoShare)
        {
            NSURL* url = [NSURL URLWithString:urlString];
            /*
             NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/help/configuration.json"]
             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
             timeoutInterval:10];
             [request setHTTPMethod: @"GET"];
             NSError *requestError;
             NSURLResponse *urlResponse = nil;
             [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
             NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             NSString *resultString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
             JSONResult *jsonResult = [[JSONResult alloc] initWithJSONString:resultString andUserData:nil];
             NSArray *resultArray = (NSArray *)jsonResult.data;
             
             //    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:resultData options:kNilOptions error:&requestError];
             */
            UIViewController *viewController = [ViewControllerHelper getCurrentRootViewController];
            
            Class socialClass = NSClassFromString(@"SLComposeViewController");
            if (socialClass != nil) {
                SLComposeViewController *twitterController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                __weak SLComposeViewController *twitterControllerForBlock = twitterController;
                twitterController.completionHandler = ^(SLComposeViewControllerResult result) {
                    [twitterControllerForBlock dismissViewControllerAnimated:YES completion:nil];
                    if (result == SLComposeViewControllerResultDone) {
                        [SVProgressHUD showSuccessWithStatus:@"Success"];
                        [[AppServices sharedAppServices] sharedNoteToTwitter:noteId];
                    }
                    
                };
                if(url)
                {
                    [twitterController addURL:url];
                    characterCountRemaining -= URL_SIZE;
                }
                if(text)
                {
                    if(text.length > characterCountRemaining) text = [text substringToIndex:characterCountRemaining];
                    while (![twitterController setInitialText:text])
                    {
                        --characterCountRemaining;
                        text = [text substringToIndex:characterCountRemaining];
                    }
                }
                if(image) [twitterController addImage:image];
                [viewController presentViewController:twitterController animated:YES completion:nil];
                
            }
            else
            {
                TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
                if(url)
                {
                    [tweetViewController addURL:url];
                    characterCountRemaining -= URL_SIZE;
                }
                if(text)
                {
                    if(text.length > characterCountRemaining) text = [text substringToIndex:characterCountRemaining];
                    while (![tweetViewController setInitialText:text])
                    {
                        --characterCountRemaining;
                        text = [text substringToIndex:characterCountRemaining];
                    }
                }
                if(image) [tweetViewController addImage:image];
                tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
                    if (result == TWTweetComposeViewControllerResultDone)
                    {
                        [SVProgressHUD showSuccessWithStatus:@"Success"];
                        [[AppServices sharedAppServices] sharedNoteToTwitter:noteId];
                    }
                    else if (result == TWTweetComposeViewControllerResultCancelled) {
                    }
                    [viewController dismissViewControllerAnimated:YES completion:nil];
                };
                
                [viewController presentViewController:tweetViewController animated:YES completion:nil];
            }
        }
        else
        {
            if(urlString)
                characterCountRemaining -= URL_SIZE;
            if(text && text.length > characterCountRemaining)
                text = [text substringToIndex:characterCountRemaining];
            
            [self autoTweetWithText:text image:image andURL:urlString fromNote:noteId];
        }

    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"Twitter Unavailable."];
    }
}

- (void) autoTweetWithText:(NSString *)text image:(UIImage *) image andURL:(NSString *) urlString fromNote:(int) noteId
{
    // Create an account store object.
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    // Create an account type that ensures Twitter accounts are retrieved.
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    // Request access from the user to use their Twitter accounts.
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            // Get the list of Twitter accounts.
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            if ([accountsArray count] > 0) {
                // Grab the initial Twitter account to tweet from.
                ACAccount *twitterAccount = [accountsArray objectAtIndex:0];
                TWRequest *postRequest = nil;
                
                NSDictionary *params = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ %@", text, urlString] forKey:@"status"];
                postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1.1/statuses/update.json"] parameters: params requestMethod:TWRequestMethodPOST];
                
                // Set the account used to post the tweet.
                [postRequest setAccount:twitterAccount];
                
                __weak id weakSelfForBlock = self;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            if ([urlResponse statusCode] == 200)
                            {
                                [SVProgressHUD showSuccessWithStatus:@"Success"];
                                [[AppServices sharedAppServices] sharedNoteToTwitter:noteId];
                            }
                            else
                            {
                                if([text length] > 0)
                                    [weakSelfForBlock autoTweetWithText:[text substringToIndex:text.length-1] image:image andURL:urlString fromNote:noteId];
                            }
                        });
                    }];
                });
                
            }
            else
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
            }
        }
    }];
}

@end