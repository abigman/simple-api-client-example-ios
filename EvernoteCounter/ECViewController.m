//
//  ECViewController.m
//  EvernoteCounter
//
//  Created by Brett Kelly on 5/7/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//

#import "ECViewController.h"
#import "EvernoteSession.h"
#import "EvernoteUserStore.h"
#import "EvernoteNoteStore.h"

@implementation ECViewController

@synthesize usernameField, noteCountField, noteCountButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)retrieveNoteCount:(id)sender
{
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithCompletionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error" 
                                                             message:@"Could not authenticate" 
                                                            delegate:nil 
                                                   cancelButtonTitle:@"OK" 
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        } else {
            NSLog(@"Authenticated successfully!");
        } 
    }];
    
    EvernoteUserStore *userStore = [EvernoteUserStore userStore];

    [userStore getUserWithSuccess:^(EDAMUser *user) {
        NSLog(@"Username: %@", user.username);
        [usernameField setText:[user username]];
        if ([session isAuthenticated]) {
            NSLog(@"Session is authenticated");
            [self countAllNotesAndSetTextField:session];
        } else {
            NSLog(@"Session not authenticated");
        }

    } failure:^(NSError *error) {
        NSLog(@"getUserWithSuccess Failed: %@", error);
    }];
       
}

- (int)countAllNotesAndSetTextField:(EvernoteSession *)session
{
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    
    __block int noteCount = 0;
    
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        
        
        for (EDAMNotebook *notebook in notebooks) {
            if ([notebook guid]) {
                EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
                [filter setNotebookGuid:[notebook guid]];
                [noteStore findNoteCountsWithFilter:filter withTrash:NO success:^(EDAMNoteCollectionCounts *counts) {
                    if (counts) {
                        NSNumber *notebookCount = (NSNumber *)[[counts notebookCounts] objectForKey:[notebook guid]];
                        NSLog(@"Notebook Count: %d", [notebookCount intValue]);
                        noteCount = noteCount + [notebookCount intValue];
                        NSLog(@"After iteration: %d", noteCount);
                    }
                } failure:^(NSError *error) {
                    NSLog(@"Did not get note counts: %@", error);
                }];
            }
        }
//        NSString *noteCountString = [NSString stringWithFormat:@"%d", noteCount];
//        NSLog(@"Count: %@", noteCountString);
//        [noteCountField setText:noteCountString];
        
    } failure:^(NSError *error) {
        NSLog(@"Error getting notebooks: %@", error);
    }];

    NSLog(@"%d", noteCount);
    return noteCount;
}

@end
