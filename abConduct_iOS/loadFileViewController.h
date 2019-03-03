//
//  loadFileViewController.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 01.03.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface loadFileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property NSMutableArray *abcDocuments;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property BOOL loadController;
@property BOOL loadTunes;
@property NSString *multiTuneFile;
@property NSString *tuneTitle;

@end

NS_ASSUME_NONNULL_END
