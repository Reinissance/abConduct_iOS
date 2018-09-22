//
//  arrayPicker.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 19.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface arrayPicker : UIPickerView  <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSArray *contentArray;
@property UIPickerView *pickerView;
@property UIColor *textColor;

- (instancetype) initWithArray: (NSArray*) array frame: (CGRect) frame andTextColour: (UIColor*) color;

@end
