//
//  exportViewController.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 04.03.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface exportViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *exportABCSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *exportCurrentSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *exportAllSwitch;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;

- (IBAction)exportSwitchesSwitched:(UISwitch *)sender;
- (IBAction)createMailButtonPushed:(id)sender;

@end

NS_ASSUME_NONNULL_END
