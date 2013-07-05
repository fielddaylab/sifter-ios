//
//  SimpleMailShare.h
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

#import "SimpleMailShare.h"
#import "AppServices.h"
#import "SVProgressHUD.h"
#import "ViewControllerHelper.h"

@implementation SimpleMailShare {
    MFMailComposeViewController *mailComposeViewController;
    int noteId;
}

- (void) dealloc {
    mailComposeViewController.mailComposeDelegate = nil;
}

- (BOOL) canSendMail {
    return [MFMailComposeViewController canSendMail];
}

//New Method
- (void) shareText:(NSString *) text asHTML:(BOOL) html withImage:(NSData *)image andSubject:(NSString *) subject toRecipients:(NSArray *) recipients fromNote:(int)aNoteId
{
    if ([self canSendMail]) {
        noteId = aNoteId;
        mailComposeViewController.mailComposeDelegate = nil;
        mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        if(recipients)
            [mailComposeViewController setToRecipients:recipients];
        if(subject)
            [mailComposeViewController setSubject:subject];
        if(text)
            [mailComposeViewController setMessageBody:text isHTML:html];
    
        [mailComposeViewController addAttachmentData:image mimeType:@"image/png" fileName:@"coolImage.png"];
        
        UIViewController *viewController = [ViewControllerHelper getCurrentRootViewController];
        [viewController presentModalViewController:mailComposeViewController animated:YES];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"E-mail Creation Error."];
    }
    
}

- (void) shareText:(NSString *)text subject:(NSString *)subject toRecipient:(NSString *)toRecipient isHTML:(BOOL)isHTML {
    if ([self canSendMail])
    {
        mailComposeViewController.mailComposeDelegate = nil;
        mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        [mailComposeViewController setSubject:subject];
        if (toRecipient) {
            [mailComposeViewController setToRecipients:@[toRecipient]];
        }
        [mailComposeViewController setMessageBody:text isHTML:isHTML];
    
        UIViewController *viewController = [ViewControllerHelper getCurrentRootViewController];
        [viewController presentModalViewController:mailComposeViewController animated:YES];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"E-mail Creation Error."];
    }
    
}

- (void) shareText:(NSString *)text subject:(NSString *)subject isHTML:(BOOL)isHTML {
    [self shareText:text subject:subject toRecipient:nil isHTML:isHTML];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if(result == MFMailComposeResultSent)
        [[AppServices sharedAppServices] sharedNoteToEmail:noteId];
    [mailComposeViewController dismissModalViewControllerAnimated:YES];
}

@end