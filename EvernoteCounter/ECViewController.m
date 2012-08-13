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
#import <CommonCrypto/CommonDigest.h>
#import "NSDataMD5Additions.h"


@implementation ECViewController
@synthesize chooseImageButton;

@synthesize usernameField, noteCountField, noteCountButton, createTestNoteButton, selectedImage, imagePickerController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [imagePickerController setDelegate:self];
}

- (void)viewDidUnload
{
    [self setChooseImageButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)logoutOfEvernoteSession:(id)sender
{
    [[EvernoteSession sharedSession] logout];
}

- (IBAction)retrieveUserNameAndNoteCount:(id)sender
{
    // Create local reference to shared session singleton
    EvernoteSession *session = [EvernoteSession sharedSession];
    
    [session authenticateWithViewController:self completionHandler:^(NSError *error) {
        // Authentication response is handled in this block
        if (error || !session.isAuthenticated) {
            // Either we couldn't authenticate or something else went wrong - inform the user
            if (error) {
                NSLog(@"Error authenticating with Evernote service: %@", error);
            }
            if (!session.isAuthenticated) {
                NSLog(@"User could not be authenticated.");
            }
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error" 
                                                             message:@"Could not authenticate" 
                                                            delegate:nil 
                                                   cancelButtonTitle:@"OK" 
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        } else {
            // We're authenticated!
            EvernoteUserStore *userStore = [EvernoteUserStore userStore];
            // Retrieve the authenticated user as an EDAMUser instance
            [userStore getUserWithSuccess:^(EDAMUser *user) {
                // Set usernameField (UILabel) text value to username
                [usernameField setText:[user username]];
                // Retrieve total note count and display it
                [self countAllNotesAndSetTextField];                
            } failure:^(NSError *error) {
                NSLog(@"Error retrieving authenticated user: %@", error);
            }];
        } 
    }];    
}


- (void)countAllNotesAndSetTextField
{
    // Allow access to this variable within the block context below (using __block keyword)
    __block int noteCount = 0;

    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        for (EDAMNotebook *notebook in notebooks) {
            if ([notebook guid]) {
                EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
                [filter setNotebookGuid:[notebook guid]];
                [noteStore findNoteCountsWithFilter:filter withTrash:NO success:^(EDAMNoteCollectionCounts *counts) {
                    if (counts) {
                        
                        // Get note count for the current notebook and add it to the displayed total
                        NSNumber *notebookCount = (NSNumber *)[[counts notebookCounts] objectForKey:[notebook guid]];
                        noteCount = noteCount + [notebookCount intValue];
                        NSString *noteCountString = [NSString stringWithFormat:@"%d", noteCount];
                        [noteCountField setText:noteCountString];
                    }
                } failure:^(NSError *error) {
                    NSLog(@"Error while retrieving note counts: %@", error);
                }];
            }
        }        
    } failure:^(NSError *error) {
        NSLog(@"Error while retrieving notebooks: %@", error);
    }];
}

- (IBAction)chooseImage:(id)sender 
{
    imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setDelegate:self];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];        
    }

    [self presentModalViewController:imagePickerController animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self setSelectedImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    NSLog(@"Image picked");
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

- (NSString*) makeMD5HashFromImageData:(NSData *)imageData
{
    NSString *hash;
    hash = [[[imageData md5] description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash substringWithRange:NSMakeRange(1, [hash length] - 2)];
    return hash;
    
    /* 
     This routine was mostly boosted from this Stack Overflow post: http://bit.ly/OUcqVn
     Submission is copyright 2011, Stack Overflow user "tommi":
     http://stackoverflow.com/users/575090/tommi
     Reproduced here in accordance with terms of the CC-WIKI with Attribution license.
    */
    
    
    /*
    
    NSString *imageString = [[NSString alloc] initWithData:imageData encoding:NSASCIIStringEncoding];
    NSLog(@"Image String, %@", imageString);
    const char *cStr = [imageString UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    NSLog(@"Hash as string: %@", output);
    //return [output dataUsingEncoding:NSASCIIStringEncoding];
 
    return output;
     
    */
}

- (void)createTestNote:(id)sender
{    
    /*
     First, do the image stuff.
    */
    // Get image as binary data, populate NSData object
    NSLog(@"Selected image: %@", [self selectedImage]);
    NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation([self selectedImage], 1.0)];
    NSString *imageHashString = [self makeMD5HashFromImageData:imageData];
    NSData *imageHashData = [imageHashString dataUsingEncoding:NSUTF8StringEncoding];

    EDAMData *edamImage = [[EDAMData alloc] initWithBodyHash:imageHashData
                                                        size:(int32_t)[imageData length]  
                                                        body:imageData];
    
    // Create and init EDAMResource instance for image
    EDAMResource *imageResource = [[EDAMResource alloc] init];
    [imageResource setData:edamImage];
    [imageResource setMime:@"image/jpeg"];
    [imageResource setHeight:[selectedImage size].height];
    [imageResource setWidth:[selectedImage size].width];
    
    EDAMResourceAttributes *imageAttributes = [[EDAMResourceAttributes alloc] init];
    [imageAttributes setFileName:@"image.jpg"];
    [imageResource setAttributes:imageAttributes];
    
    NSLog(@"Height: %d", [imageResource height]);
    NSLog(@"Width: %d", [imageResource width]);
    NSLog(@"Image hash: %@", imageHashString);
    NSLog(@"Image type: %@", [imageResource mime]);
    
    NSString *xml = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    NSString *doctype = @"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">";
    NSString *mediaResource = [[NSString alloc] initWithFormat:@"<en-media type=\"%@\" width=\"%d\" height=\"%d\" hash=\"%@\" />", [imageResource mime], [imageResource width], [imageResource height], imageHashString];

    EDAMNote *note = [[EDAMNote alloc] init];
    [note setTitle:@"Test Note from EvernoteCounter for iPhone"];
    [note setContent:[[NSString alloc] initWithFormat:@"%@%@<en-note>%@</en-note>", xml, doctype, mediaResource]];
    [note setResources:[[NSArray alloc] initWithObjects:imageResource, nil]];
    

    /*
    Create the note.
    */
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    
    [noteStore createNote:(note) success:^(EDAMNote *note) {
        NSLog(@"Received note guid: %@", [note guid]);
    } failure:^(NSError *error) {
        NSLog(@"Create note failed: %@", error);
    }];
}


- (void)dealloc {
    [chooseImageButton release];
    [super dealloc];
}
@end
