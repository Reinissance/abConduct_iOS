//
//  createFileViewController.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.01.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import "createFileViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"

#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define controller ((ViewController *)[[(AppDelegate*)APP window] rootViewController])

@interface createFileViewController ()

@property NSString *createFileName;
@property NSString *createFileComposer;
@property NSString *createFileLength;
@property NSString *createFileVoices;
@property NSMutableArray *voiceSettings;
@property NSArray *voiceSettingSelection;
@property NSMutableArray *voiceSettingOption;
@property NSArray *instruments;

@end

@implementation createFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _Keys = @[@"C#", @"F#", @"B", @"E", @"A", @"D", @"G", @"C", @"F", @"Bb", @"Eb", @"Ab", @"Db", @"Gb"];
//    _keyPicker = [[arrayPicker alloc] initWithArray:Keys frame:CGRectMake(30, 80, 100, 100) andTextColour:[UIColor redColor]];
    
    _Measures = @[@"2/4", @"3/4", @"4/4", @"2/2", @"3/8", @"6/8", @"12/8", @"5/8", @"5/4", @"6/4", @"7/4", @"9/8", @"7/8"];
//    _measurePicker = [[arrayPicker alloc] initWithArray:Measures frame:CGRectMake(140, 80, 100, 100) andTextColour:[UIColor darkTextColor]];
    [_keyPicker setDelegate:self];
    [_keyPicker setDataSource:self];
    [_keyPicker reloadComponent:0];
    [_measurePicker setDelegate:self];
    [_measurePicker setDataSource:self];
    [_measurePicker reloadComponent:0];
    [_keyPicker selectRow:7 inComponent:0 animated:NO];
    [_measurePicker selectRow:2 inComponent:0 animated:NO];
    
    [_fileTitle addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    _fileTitle.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_fileTitle.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5]}];
    [_composer addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    [_noteLength addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    [_voices addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    _scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width, 757);
    _voiceSettings = [NSMutableArray array];
}


-(void)textDidChange:(UITextField *)textField {
    if (textField.tag == 0) {
        _createButton.enabled = (textField.text.length > 0);
        _createFileName = textField.text;
    }
    else if (textField.tag == 1) {
        _createFileComposer = textField.text;
    }
    else if (textField.tag == 2) {
        if (![textField.text isEqualToString:@"/"] && textField.text.length == 1) {
            textField.text = [textField.text stringByAppendingString:@"/"];
        }
        _createFileLength = textField.text;
    }
    else if (textField.tag == 3) {
        _createFileVoices = textField.text;
        if (!_voiceSettingSelection) {
            _voiceSettingSelection = @[];
            [_voiceSettingsPicker setDelegate:self];
            [_voiceSettingsPicker setDataSource:self];
        }
        NSMutableArray *voices = [[_createFileVoices componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
        [voices removeObject:@""];
        int changeIndex = (int) voices.count-1;
        if (voices.count > _voiceSettings.count) {
            NSMutableArray *voice = [NSMutableArray arrayWithObjects:voices[voices.count-1], @"no ", @"no ", @"no ", @"no ", @"no ", nil];
            [_voiceSettings addObject:voice];
        }
        else if (voices.count < _voiceSettings.count)
                 [_voiceSettings removeLastObject];
        else {
            for (int i = 0; i < _voiceSettings.count; i++) {
                NSMutableArray *voice= _voiceSettings[i];
                if (![voices[i] isEqualToString:voice[0]]) {
                    changeIndex = i;
                    [voice replaceObjectAtIndex:0 withObject:voices[i]];
                    [_voiceSettings replaceObjectAtIndex:i withObject:voice];
                }
            }
        }
        [_voiceSettingsPicker reloadAllComponents];
        if (_voiceSettings.count == 0) {
            _voiceSettingSelection = @[];
            [_voiceSettingOption removeAllObjects];
        }
        else {
            [_voiceSettingsPicker selectRow:changeIndex inComponent:0 animated:NO];
            [self pickerView:_voiceSettingsPicker didSelectRow:_voiceSettings.count-1 inComponent:0];
            [self pickerView:_voiceSettingsPicker didSelectRow:[_voiceSettingsPicker selectedRowInComponent:1] inComponent:1];
            if (_voiceSettingSelection.count == 0)
                _voiceSettingSelection = @[@"no setting:", @"clef", @"transpose", @"program", @"panning", @"volume"];
        }
    }
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    if (pickerView != _voiceSettingsPicker) {
        return 1;
    }
    else return 3;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView != _voiceSettingsPicker) {
        if (pickerView == _keyPicker)
            return _Keys.count;
        else
            return _Measures.count;
    }
    else if (component == 0)
        return _voiceSettings.count;
    else if (_voiceSettings.count > 0) {
        if (component == 1)
            return _voiceSettingSelection.count;
        else return _voiceSettingOption.count;
    }
    else return 0;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component   {
    if (pickerView != _voiceSettingsPicker) {
        if (pickerView == _keyPicker)
            return _Keys[row];
        else
            return _Measures[row];
    }
    else {
        if (component == 0) {
            NSArray *voice = [_voiceSettings[row] copy];
            return voice [0];
        }
        else if (component == 1)
            return _voiceSettingSelection[row];
        else return _voiceSettingOption[row];
    }
}

#pragma mark - UIPickerView Delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component  {
    if (pickerView == _voiceSettingsPicker) {
        if (component == 0) {
            [self pickerView:_voiceSettingsPicker didSelectRow:[_voiceSettingsPicker selectedRowInComponent:1] inComponent:1];
        }
        NSMutableArray *voice = _voiceSettings[[_voiceSettingsPicker selectedRowInComponent:0]];
        if (component == 1) {
            if (row == 0)
                [_voiceSettingOption removeAllObjects];
            else if (row == 1) {
                _voiceSettingOption = [NSMutableArray arrayWithObjects:@"no clef set", @"treble", @"bass", @"bass3", @"tenor", @"alto", @"alto2", @"alto1", nil];
            }
            else if (row == 2) {
                [_voiceSettingOption removeAllObjects];
                for (int i = 0; i < 25; i++) {
                    [_voiceSettingOption addObject: (i != 12) ? [NSString stringWithFormat:@"%d", i-12] : @"no transposition set"];
                }
            }
            else if (row == 3) {
                NSError *error;
                if (!_instruments) {
                    NSString *insts = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"midiInstruments" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
                    if (error) {
                        NSLog(@"couldn't read instrumentFile: %@", error.localizedFailureReason);
                    }
                    _instruments = [insts componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                }
                _voiceSettingOption = [NSMutableArray arrayWithObject:@"no instrument set"];
                for (NSString *inst in _instruments) {
                    if (![inst isEqualToString:@""])
                        [_voiceSettingOption addObject:inst];
                }
            }
            else if (row == 4) {
                _voiceSettingOption = [NSMutableArray arrayWithObject:@"no panning set"];
                for (int i = 0; i < 128; i++) {
                    [_voiceSettingOption addObject:[NSString stringWithFormat:@"%d", i]];
                }
            }
            else if (row == 5) {
                _voiceSettingOption = [NSMutableArray arrayWithObject:@"no volume set"];
                for (int i = 0; i < 128; i++) {
                    [_voiceSettingOption addObject:[NSString stringWithFormat:@"%d", i]];
                }
            }
            [_voiceSettingsPicker reloadComponent:2];
            if (row > 0) {
                NSString *setting = voice[[_voiceSettingsPicker selectedRowInComponent:1]];
                if ([setting hasPrefix:@"no "]) {
                    [_voiceSettingsPicker selectRow:(row != 2) ? 0 : 12 inComponent:2 animated:YES];
                }
                else [_voiceSettingsPicker selectRow:[_voiceSettingOption indexOfObject:setting] inComponent:2 animated:YES];
            }
        }
        else if (component == 2) {
            [voice replaceObjectAtIndex:[_voiceSettingsPicker selectedRowInComponent:1] withObject:_voiceSettingOption[[_voiceSettingsPicker selectedRowInComponent:2]]];
            [_voiceSettings replaceObjectAtIndex:[_voiceSettingsPicker selectedRowInComponent:0] withObject:voice];
        }
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
    }
    [tView setTextAlignment:NSTextAlignmentCenter];
    if (pickerView != _voiceSettingsPicker) {
        tView.text = (pickerView == _keyPicker) ? _Keys[row] :  _Measures[row];
        tView.font = [UIFont systemFontOfSize:14];
        tView.textColor = (pickerView == _keyPicker) ? [UIColor redColor] : [UIColor darkTextColor];
    }
    else if (component == 0) {
        NSArray *voice = [_voiceSettings[row] copy];
        tView.text = voice[0];
        tView.font = [UIFont systemFontOfSize:14];
    }
    else if (component == 1) {
        tView.text = _voiceSettingSelection[row];
        tView.font = [UIFont systemFontOfSize:12];
        tView.textColor = [UIColor brownColor];
    }
    else if (component == 2) {
        tView.text = _voiceSettingOption[row];
        tView.font = [UIFont systemFontOfSize:10];
        tView.textColor = [UIColor orangeColor];
    }

    return tView;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    if (pickerView != _voiceSettingsPicker)
        return 17;
    else return 15;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    switch (component){
        case 0:
            return 50.0f;
        case 1:
            return 60.0f;
        case 2:
            return 120.0f;
    }
    return 0;
}

- (IBAction)createFile:(id)sender {
    BOOL extension = ((_createFileName.length > 4) && [[_createFileName substringFromIndex:_createFileName.length-4] isEqualToString:@".abc"]);
    _createFileVoices = (_voices.text.length > 0) ? _voices.text : @"Voice1";
    NSString *createAbcFileString = [NSString stringWithFormat:@"X:1\n%@\nT:%@\n", [NSString stringWithFormat:@"%@ %@ %@ scale=0.7", @"\%\%staves", _createFileVoices, @"\%Partitur"], (extension) ? [_createFileName substringToIndex:_createFileName.length-4] : _createFileName];
    if (_createFileComposer != nil && ![_createFileComposer isEqualToString:@""]) {
        createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"C:%@\n", _createFileComposer]];
    }
    if (_createFileLength != nil && ![_createFileLength isEqualToString:@""]) {
        createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"L:%@\n", _createFileLength]];
    }
    createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"M:%@\n", _Measures[[_measurePicker selectedRowInComponent:0]]]];
    createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"K:%@\n", _Keys[[_keyPicker selectedRowInComponent:0]]]];
    NSLog(@"file created: %@", createAbcFileString);
    if (_voiceSettings.count == 0) {
        [_voiceSettings addObject:[@[@"Voice1", @"no nothing"] mutableCopy]];
    }
    for (NSMutableArray *voice in _voiceSettings) {
        createAbcFileString = [[createAbcFileString stringByAppendingString: @"V:"] stringByAppendingString: voice[0]];
        for (int i = 1; i < voice.count; i++) {
            NSString *value = voice[i];
            if (![value hasPrefix:@"no "]) {
                if (i == 1) {
                    createAbcFileString = [createAbcFileString stringByAppendingString:[NSString stringWithFormat:@" clef=%@", value]];
                }
                else if (i == 2) {
                    createAbcFileString = [createAbcFileString stringByAppendingString:[NSString stringWithFormat:@" transpose=%@", value]];
                }
                else if (i == 3) {
                    createAbcFileString = [createAbcFileString stringByAppendingString:@"\n\%\%MIDI program "];
                    NSUInteger index = [_instruments indexOfObject:value];
                    createAbcFileString = [[[createAbcFileString stringByAppendingString:[NSString stringWithFormat:@"%lu ", (unsigned long)index]] stringByAppendingString:@"\%"] stringByAppendingString:value];
                }
                else if (i == 4) {
                    createAbcFileString = [[createAbcFileString stringByAppendingString:@"\n\%\%MIDI control 10 "] stringByAppendingString:value];
                }
            }
        }
        createAbcFileString = [[createAbcFileString stringByAppendingString:@"\n\%start writing voice "] stringByAppendingString:[NSString stringWithFormat:@"%@ here:\n", voice[0]]];
    }
    [controller setColouredCodeFromString: createAbcFileString];
    NSError *error;
    NSString *path = [docsPath stringByAppendingPathComponent:[_createFileName stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    if (!extension) {
        path = [path stringByAppendingPathExtension:@"abc"];
    }
    controller.filepath = [NSURL fileURLWithPath:path];
    BOOL write = [controller.abcView.textView.text writeToURL:controller.filepath atomically:NO encoding:controller.encoding error:&error];
    if (!write) {
        NSLog(@"could not write file %@: %@", controller.filepath, error);
    }
    else {
        controller.refreshButton.enabled = YES;
        controller.saveButton.enabled = YES;
        [controller.allVoices removeAllObjects];
        controller.allVoices = [controller getVoicesWithHeader];
        NSArray *tune = controller.allVoices[0];
        NSMutableArray *tuneArray = tune[1];
        [[controller voiceSVGpaths] createVoices:tuneArray];
        controller.selectedVoice = [tune[0] stringByAppendingString:@"_Partitur"];
        [controller loadSvgImage];
    }
    [self dismiss];
}

- (IBAction)cancel:(id)sender {
    [self dismiss];
}

-(void) dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
