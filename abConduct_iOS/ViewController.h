//
//  ViewController.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PDFKit/PDFView.h>

@class WebServer;

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet PDFView *displayView;
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

@property (weak, nonatomic) WebServer *server;

@end
