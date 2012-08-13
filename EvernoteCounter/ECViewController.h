//
//  ECViewController.h
//  EvernoteCounter
//
//  Created by Brett Kelly on 5/7/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//

#import <UIKit/UIKit.h>
// #import <ApplicationServices/ApplicationServices.h>

@interface ECViewController : UIViewController 
    <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *usernameField;
@property (strong, nonatomic) IBOutlet UILabel *noteCountField;
@property (strong, nonatomic) IBOutlet UIButton *noteCountButton;
@property (strong, nonatomic) IBOutlet UIButton *createTestNoteButton;
@property (strong, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (strong, nonatomic) UIImage *selectedImage;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

- (IBAction)logoutOfEvernoteSession:(id)sender;
- (IBAction)createTestNote:(id)sender;
- (IBAction)retrieveUserNameAndNoteCount:(id)sender;
- (IBAction)chooseImage:(id)sender;

@end
