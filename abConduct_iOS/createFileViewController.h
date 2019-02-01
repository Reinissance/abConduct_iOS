//
//  createFileViewController.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.01.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "arrayPicker.h"

@interface createFileViewController : UIViewController  <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) IBOutlet UIPickerView *keyPicker;
@property (nonatomic) IBOutlet UIPickerView *measurePicker;
@property (weak, nonatomic) IBOutlet UITextField *fileTitle;
@property (weak, nonatomic) IBOutlet UITextField *composer;
@property (weak, nonatomic) IBOutlet UITextField *noteLength;
@property (weak, nonatomic) IBOutlet UITextField *voices;
@property NSArray *Keys;
@property NSArray *Measures;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
- (IBAction)createFile:(id)sender;
- (IBAction)cancel:(id)sender;
@property (weak, nonatomic) IBOutlet UIPickerView *voiceSettingsPicker;

- (void) dismiss;
@end
