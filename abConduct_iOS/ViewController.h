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

@class WebServer;

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, midiPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIWebView *displayView;
@property (weak, nonatomic) IBOutlet UITextView *abcView;
- (IBAction)moveHorizontalStack:(UIPanGestureRecognizer *)sender;
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

@end
