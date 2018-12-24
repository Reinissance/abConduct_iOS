//
//  ViewController.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "midiPlayer.h"
#import "LineNumberTextViewWrapper.h"
#import <MessageUI/MessageUI.h>

@class WebServer;

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, midiPlayerDelegate, UITextViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIWebView *displayView;
@property (assign, nonatomic) IBOutlet LineNumberTextViewWrapper* abcView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *abcViewBottom;
- (IBAction)moveHorizontalStack:(UIPanGestureRecognizer *)sender;
- (IBAction)toggleLogExpansion:(id)sender;
- (IBAction)expandLog:(UIPanGestureRecognizer *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *logSwitch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonViewHeight;
- (IBAction)buttonViewSizeToggle:(id)sender;
- (IBAction)buttonPressed:(UIButton *)sender;
- (IBAction)zoomText:(UIPinchGestureRecognizer *)sender;
- (IBAction)startHTTPserver:(UISwitch *)sender;
- (IBAction)codeHighlightingEnabled:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UILabel *serverLabel;
@property (weak, nonatomic) IBOutlet UISwitch *serverSwitch;
- (IBAction)hideKeyboard:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *codeHighlightingLabel;
- (IBAction)exportMIDI:(UIButton*)sender;

@property (weak, nonatomic) WebServer *server;
- (void) loadABCfileFromPath: (NSString*) path;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
- (IBAction)loadUserSoundFont:(id)sender;
- (void) logText: (NSString *) log;
@property (weak, nonatomic) IBOutlet UILabel *logSwitchLabel;
- (IBAction)enableLog:(UISwitch*)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logHeight;
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UISwitch *codeHighlightingSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *playbackProgress;
- (IBAction)exportDocument:(id)sender;
- (IBAction)clearLog:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *sfButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *skipControl;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;

- (IBAction)skip:(UISegmentedControl *)sender;

@end
