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

- (void) shareText:(NSString *)text withImage:(UIImage *) image andURL:(NSString *) urlString fromNote:(int) noteId
{
    if ([self canSendTweet])
    {
        int characterCountRemaining = TWEET_SIZE;
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
            if(url)   [twitterController addURL:url];
            characterCountRemaining -= URL_SIZE;
            if(text)
            {
                if(text.length > characterCountRemaining) text = [text substringFromIndex:characterCountRemaining];
                while (![twitterController setInitialText:text])
                {
                    --characterCountRemaining;
                    text = [text substringFromIndex:characterCountRemaining];
                }
            }
            if(image) [twitterController addImage:image];
            [viewController presentViewController:twitterController animated:YES completion:nil];
            
        }
        else
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            if(url)   [tweetViewController addURL:url];
            if(text)
            {
                if(text.length > characterCountRemaining) text = [text substringFromIndex:characterCountRemaining];
                while (![tweetViewController setInitialText:text])
                {
                    --characterCountRemaining;
                    text = [text substringFromIndex:characterCountRemaining];
                }
            }
            if(image) [tweetViewController addImage:image];
            tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
                if (result == TWTweetComposeViewControllerResultDone) {
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
        [SVProgressHUD showErrorWithStatus:@"Twitter Unavailable."];
    }
}

@end