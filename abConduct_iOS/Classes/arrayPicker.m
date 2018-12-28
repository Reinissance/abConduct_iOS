//
//  arrayPicker.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 19.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "arrayPicker.h"

@interface UIPickerView()
- (void)setSoundsEnabled:(BOOL)bValue;
@end

@implementation arrayPicker

- (instancetype) initWithArray: (NSArray*) array frame: (CGRect) frame andTextColour: (UIColor*) color {
    _components = 1;
    _contentArray = [NSArray arrayWithArray:array];
    _textColor = color;
    _pickerView = [[UIPickerView alloc] initWithFrame:frame];
    _pickerView.showsSelectionIndicator = YES;
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    [_pickerView setSoundsEnabled:NO];
    
    return self;
}



- (instancetype) initWithFirstArray: (NSArray*) array secondArray: (NSArray*) array2 frame: (CGRect) frame andTextColour: (UIColor*) color {
    _components = 2;
    _contentArray = [NSArray arrayWithArray:array];
    _secondContentArray = [NSArray arrayWithArray:array2];
    _textColor = color;
    _pickerView = [[UIPickerView alloc] initWithFrame:frame];
    _pickerView.showsSelectionIndicator = YES;
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    [_pickerView setSoundsEnabled:NO];
    
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return _components;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (_components == 1) {
        return _contentArray.count;
    }
    else if (component == 0) return _contentArray.count;
    else return _secondContentArray.count;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component   {
    if (_components == 1) {
        return self.contentArray[row];
    }
    else if (component == 0) {
        return self.contentArray[row];
    }
    else return self.secondContentArray[row];
}

#pragma mark - UIPickerView Delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component  {
    NSLog(@"key Picked:%@", (component == 0) ? self.contentArray[row] :  self.secondContentArray[row]);
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
    }
    [tView setTextAlignment:NSTextAlignmentCenter];
    //    tView.frame = CGRectMake(0, 0, 50, 12);
    tView.text = (component == 0) ? self.contentArray[row] :  self.secondContentArray[row];
    tView.font = [UIFont systemFontOfSize:12];
    tView.textColor = _textColor;
    
    return tView;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 15;
}

@end
