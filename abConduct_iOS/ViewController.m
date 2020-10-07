//
//  ViewController.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "arrayPicker.h"
#include <string.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "store.h"
#import <STPopup/STPopup.h>
#import "createFileViewController.h"
#import "loadFileViewController.h"
#import "exportViewController.h"
#import "toabc.h"

#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface ViewController () <UIDocumentPickerDelegate> {
}

@property BOOL buttonViewExpanded;
@property NSMutableArray *potentialVoices;
@property BOOL codeHighlighting;
@property arrayPicker *instrumentsPicker;
@property NSArray *userSoundfonts;
@property NSMutableArray *decorations;
@property midiPlayer *mp;
@property NSURL *soundfontUrl;
@property BOOL logEnabled;
@property CGFloat fontSize;
@property BOOL keyboard;
@property BOOL skipping;
@property STPopupController *createFilePopup;
@property STPopupController *loadFilePopup;
@property STPopupController *exportPopup;
@property NSString *transposedString;

@end

@implementation ViewController

- (void) orientationChanged {
    [UIView animateWithDuration:0.1 animations:^{
        self->_webDisplayView.frame = CGRectMake(self->_displayView.frame.origin.x-2, self->_displayView.frame.origin.y-4, self->_displayView.frame.size.width, self->_displayView.frame.size.height);
    }];
}

- (void)viewDidLoad {
    
    codeAssist = YES;
    autoRefresh = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged)    name:UIDeviceOrientationDidChangeNotification  object:nil];

    //create WKWebView
    _webDisplayView = [[WKWebView alloc] initWithFrame:CGRectMake(_displayView.frame.origin.x-2, _displayView.frame.origin.y-2, _displayView.frame.size.width, _displayView.frame.size.height)];
    [_displayView addSubview:_webDisplayView];
    
    _tuneSelected = -1;
    _directMode = NO;
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _encoding = NSUTF8StringEncoding;
    NSString *file = [[NSBundle mainBundle] pathForResource:@"Hallelujah" ofType:@"abc" inDirectory: @"DefaultFiles"];
    _filepath = [NSURL fileURLWithPath:file];
    NSString *content = [self stringWithContentsOfEncodedFile:[_filepath path]];
    _logString = @"";
    _codeHighlighting = YES;
    _fontSize = 12.0;
    [self setColouredCodeFromString:content];
    _allVoices = [NSMutableArray array];
    _allVoices = [self getVoicesWithHeader];
    _voiceSVGpaths = [[voiceHandler alloc] init];
    NSArray *tune = _allVoices[0];
    NSMutableArray *tuneArray = tune[1];
    [_voiceSVGpaths createVoices:tuneArray];
    NSArray *voice = tuneArray[0];
    _selectedVoice = voice[0];
    [self loadSvgImage];
    self.server = APP.server;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    NSString *sfPath = [[NSBundle mainBundle] pathForResource:@"32MbGMStereo" ofType:@"sf2" inDirectory:@"DefaultFiles"];
    _soundfontUrl = [[NSURL alloc] initFileURLWithPath:sfPath];
    _abcView.textView.delegate = self;
    _abcView.delegate = self;
    [_abcView.textView setTintColor:[UIColor whiteColor]];
    _abcView.textView.backgroundColor = [UIColor colorWithHue:41.0/360.0 saturation:11.0/360.0 brightness:84.0/360.0 alpha:0.0];
    _abcView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    if (@available(iOS 11.0, *)) {
        _abcView.textView.smartQuotesType = UITextSmartQuotesTypeNo;
    }
    #if TARGET_OS_MACCATALYST
    #else
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.window.frame.size.width, 44.0f)];
    toolbar.tintColor = [UIColor blackColor];
    toolbar.translucent = YES;
    toolbar.items = @[[[UIBarButtonItem alloc] initWithTitle: @"|" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"/" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"^" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"_" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"=" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"'" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"," style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"-" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"." style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @":" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"[" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"]" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"(" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @")" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"!" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"\"" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"%" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"<" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @">" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"~" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"*" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                        [[UIBarButtonItem alloc] initWithTitle: @"decorations" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"dynamics" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"structure" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"directives" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                        [[UIBarButtonItem alloc] initWithTitle: @"undo" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle: @"redo" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      ];
    toolbar.frame = CGRectMake(0, 0, 1200, 44);
    toolbar.autoresizingMask = UIViewAutoresizingNone;
    UIScrollView *toolScroll = [[UIScrollView alloc] initWithFrame:toolbar.frame];
    toolScroll.contentSize = toolbar.frame.size;
    [toolScroll addSubview:toolbar];
    _abcView.textView.inputAccessoryView = toolScroll;
    #endif
    _playbackProgress.progress = 0.0;
    
    NSMutableArray *items = [[[UIMenuController sharedMenuController] menuItems] mutableCopy];
    if (!items) items = [[NSMutableArray alloc] init];
    UIMenuItem *transposeItem;
    transposeItem = [[UIMenuItem alloc] initWithTitle:@"transpose" action:@selector(transpose:)];
    [items addObject:transposeItem];
    UIMenuItem *instItem;
    instItem = [[UIMenuItem alloc] initWithTitle:@"change program" action:@selector(changeProgram: inRange:)];
    [items addObject:instItem];
    UIMenuItem *panItem;
    panItem = [[UIMenuItem alloc] initWithTitle:@"panning" action:@selector(changeControl:inRange:)];
    [items addObject:panItem];
    UIMenuItem *drummapItem;
    drummapItem = [[UIMenuItem alloc] initWithTitle:@"drummap" action:@selector(changeDrummap: inRange:)];
    [items addObject:drummapItem];
    [[UIMenuController sharedMenuController] setMenuItems:items];
    UILongPressGestureRecognizer *toggleMode = [[UILongPressGestureRecognizer  alloc] initWithTarget:self action:@selector(longPressModeToggle:)];
    [_displayBtn addGestureRecognizer:toggleMode];
    
      if (@available(iOS 11.0, *)) {
          UIDropInteraction *dropper = [[UIDropInteraction alloc] initWithDelegate:self];
          [self.view addInteraction:dropper];
      }
}

- (void) longPressModeToggle: (UILongPressGestureRecognizer*) gesture {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        _directMode = !_directMode;
        [_displayBtn setTitle:(_directMode) ? @"direct" : @"display" forState: UIControlStateNormal];
        [_displayBtn setTitleColor:(_directMode) ? [UIColor whiteColor] : [UIColor magentaColor] forState:UIControlStateNormal];
        [self render];
    }
}

- (void) changeControl: (NSString *) lineString inRange: (NSRange) lineRange  {
    if (pickershown)
        return;
    else pickershown = YES;
    NSArray *words;
    float number = 10;
    float value = 64;
    if (lineString.class != UIMenuController.class) {
        words = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        if (words.count > 3) {
            if ([nf numberFromString:words[3]] != nil) {
                value = [words[3] floatValue];
            }
            if ([nf numberFromString:words[2]] != nil) {
                number = [words[2] floatValue];
            }
        }
    }
    else lineRange = _abcView.textView.selectedRange;
    NSString *control = [NSString stringWithFormat:@"%@", (number == 10) ? @"panning" : (number == 7) ? @"volume" : @"control"];
    NSString *title = [NSString stringWithFormat:@"set the %@:", control];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:@"\n\n" preferredStyle:UIAlertControllerStyleAlert];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 60, 230, 20)];
    slider.maximumValue = 127;
    [slider setValue:value];
    [alertController.view addSubview:slider];
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat: @"set %@", control] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *replaceString = [[[@"\%\%" stringByAppendingString:[NSString stringWithFormat:@"MIDI control %d %d", (int)number, (int)roundf(slider.value)]] stringByAppendingString:@" \%"] stringByAppendingString:control];
        [self setColouredCodeFromString:[self->_abcView.textView.text stringByReplacingCharactersInRange:lineRange withString:replaceString]];
        pickershown = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        pickershown = NO;
    }];
    [alertController addAction:selectAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

BOOL pickershown;

- (void) changeProgram: (NSString *) lineString inRange: (NSRange) lineRange  {
    if (pickershown)
        return;
    else pickershown = YES;
    NSArray *words;
    float number = 0;
    if (lineString.class != UIMenuController.class) {
        words = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        if (words.count > 2 && [nf numberFromString:words[2]] != nil) {
            number = [words[2] floatValue];
        }
        lineRange = [self selectedLineRange];
    }
    else lineRange = _abcView.textView.selectedRange;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select instrument:" message:@"\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    NSError *error = nil;
    NSString *insts = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"midiInstruments" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"couldn't read instrumentFile: %@", error.localizedFailureReason);
    }
    NSArray *instruments = [insts componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    _instrumentsPicker = [[arrayPicker alloc] initWithArray:instruments frame:CGRectMake(40, 50, 200, 80) andTextColour:[UIColor brownColor]];
    [alertController.view addSubview:_instrumentsPicker.pickerView];
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"select" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *instName = instruments[[self->_instrumentsPicker.pickerView selectedRowInComponent:0]];
        NSString *replaceString = [@"\%\%" stringByAppendingString:[NSString stringWithFormat:@"MIDI program %ld", (long)[self->_instrumentsPicker.pickerView selectedRowInComponent:0]]];
        replaceString = [[replaceString stringByAppendingString:@" \%"] stringByAppendingString:instName];
        [self setColouredCodeFromString:[self->_abcView.textView.text stringByReplacingCharactersInRange:lineRange withString:replaceString]];
        pickershown = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [_instrumentsPicker.pickerView selectRow:number inComponent:0 animated:NO];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        pickershown = NO;
    }];
    [alertController addAction:selectAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void) changeDrummap: (NSString *) lineString inRange: (NSRange) lineRange  {
    if (pickershown)
        return;
    else pickershown = YES;
    NSLog(@"Now show the drummap");
    NSArray *words;
    float number = 0;
    NSString *note = @"F";
    if (lineString.class != UIMenuController.class) {
        words = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        if (words.count > 3 && [nf numberFromString:words[3]] != nil) {
            number = [words[3] floatValue]-36;
            note = words[2];
        }
    }
    else lineRange = _abcView.textView.selectedRange;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"add drummap:" message:@"select note and drumsound:\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    NSError *error = nil;
    NSString *snds = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"drummapSounds" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"couldn't read instrumentFile: %@", error.localizedFailureReason);
    }
    NSArray *notes = [[NSArray alloc] initWithObjects:@"_C", @"C", @"^C", @"_D", @"D", @"^D", @"_E", @"E", @"^E", @"_F", @"F", @"^F", @"_G", @"G", @"^G", @"_A", @"A", @"^A", @"_B", @"B", @"^B", @"_c", @"c", @"^c", @"_d", @"d", @"^d", @"_e", @"e", @"^e", @"_f", @"f", @"^f", @"_g", @"g", @"^g", @"_a", @"a", @"^a", @"_b", @"b", @"^b", @"_c'", @"c'", @"^c'", nil];
    NSArray *sounds = [snds componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    _instrumentsPicker = [[arrayPicker alloc] initWithFirstArray:notes secondArray:sounds frame:CGRectMake(40, 50, 200, 80) andTextColour:[UIColor brownColor]];
    [alertController.view addSubview:_instrumentsPicker.pickerView];
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *selectedNote = notes[[self->_instrumentsPicker.pickerView selectedRowInComponent:0]];
        NSString *soundName = sounds[[self->_instrumentsPicker.pickerView selectedRowInComponent:1]];
        NSString *replaceString = [@"\%\%" stringByAppendingString:[NSString stringWithFormat:@"MIDI drummap %@ %ld", selectedNote, (long)[self->_instrumentsPicker.pickerView selectedRowInComponent:1]+36]];
        replaceString = [[replaceString stringByAppendingString:@" \%"] stringByAppendingString:soundName];
        [self setColouredCodeFromString:[self->_abcView.textView.text stringByReplacingCharactersInRange:lineRange withString:replaceString]];
        pickershown = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [_instrumentsPicker.pickerView selectRow:[notes indexOfObject:note] inComponent:0 animated:NO];
    [_instrumentsPicker.pickerView selectRow:number inComponent:1 animated:NO];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        pickershown = NO;
        
    }];
    [alertController addAction:selectAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.view layoutIfNeeded];
    [_abcView.textView addObserver:self forKeyPath:@"selectedTextRange" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context {
    if (codeAssist) {
        if ([keyPath isEqualToString:@"selectedTextRange"] && _abcView.textView == object) {
            NSRange lineRange = [self selectedLineRange];
            NSString *selectedLine = [_abcView.textView.text substringWithRange:lineRange];
            if (selectedLine.length >= 14) {
                if ([[selectedLine substringToIndex:14] isEqualToString:@"%%MIDI program"]) {
                    [self changeProgram:selectedLine inRange: lineRange];
                }
                else if ([[selectedLine substringToIndex:14] isEqualToString:@"%%MIDI control"]) {
                    [self changeControl:selectedLine inRange:lineRange];
                }
                else if ([[selectedLine substringToIndex:14] isEqualToString:@"%%MIDI drummap"]) {
                    [self changeDrummap:selectedLine inRange:lineRange];
                }
            }
        }
    }
}

- (NSRange) selectedLineRange {
    UITextRange *caretPositionRange = _abcView.textView.selectedTextRange;
    UITextPosition *pos = caretPositionRange.start;
    id<UITextInputTokenizer> tokenizer = [_abcView.textView tokenizer];
    UITextPosition *startOfLine = [tokenizer positionFromPosition:pos toBoundary:UITextGranularityParagraph inDirection:UITextStorageDirectionBackward];
    UITextPosition *endOfLine = [tokenizer positionFromPosition:pos toBoundary:UITextGranularityParagraph inDirection:UITextStorageDirectionForward];
    NSRange lineRange = _abcView.textView.selectedRange;
    if (startOfLine != nil && endOfLine != nil && startOfLine != endOfLine) {
        NSUInteger startPosition = [_abcView.textView offsetFromPosition:_abcView.textView.beginningOfDocument toPosition:startOfLine];
        NSUInteger endPosition = [_abcView.textView offsetFromPosition:_abcView.textView.beginningOfDocument toPosition:endOfLine];
        lineRange = NSMakeRange(startPosition, endPosition-startPosition);
    }
    return lineRange;
}

- (void) performTransposition: (NSInteger) transposition {
    NSString *tmpFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"transpose"] stringByAppendingPathExtension:@"abc"];
    [_voiceSVGpaths cleanTempFolder];
    NSError *error;
    UITextRange *selectedRange = [_abcView.textView selectedTextRange];
    NSString *abcCode = [_abcView.textView textInRange:selectedRange];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n+" options:0 error:NULL];
    abcCode = [regex stringByReplacingMatchesInString:abcCode options:0 range:NSMakeRange(0, [abcCode length]) withTemplate:@"\n"];
    NSLog(@"code to transpose: %@", abcCode);
    NSString *lineText = [_abcView.textView.text substringWithRange:[self selectedLineRange]];
    if ([[lineText substringFromIndex:lineText.length-1] isEqualToString:@"\n"])
        lineText = [lineText substringToIndex:lineText.length-1];
    NSArray *codeLines = [_abcView.textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    int lineNum = (int) [codeLines indexOfObject:lineText];
    if (lineNum == 0)
        lineNum = (int)codeLines.count-1;
    BOOL noKeyFromVoice = NO;
    BOOL removeHeader = NO;
    //search key in Voice
    NSString *keyline = @"";
    NSString *metrumLine = @"";
    NSString *lengthLine = @"";
    NSMutableArray *voices = [NSMutableArray array];
    for (int i = lineNum; i > 1; i--) {
        NSString *line = codeLines[i];
        if ([line hasPrefix:@"V:"]) {
            //not found in Voice
            noKeyFromVoice = YES;
            [voices insertObject:line atIndex:0];
            abcCode = [abcCode stringByReplacingOccurrencesOfString:line withString:[NSString stringWithFormat:@"V:%d", i]];
        }
        else if ([line containsString:@"K:"]) {
            if ([line hasPrefix:@"K:"] && noKeyFromVoice && [keyline isEqualToString:@""]) {
                //found in header
                keyline = [line stringByAppendingString:@"\n"];
            }
            else if (!noKeyFromVoice) {
                //extract key from line in Voice
                NSRange range = [line rangeOfString:@"K:"];
                NSUInteger startPos = range.location;
                unsigned int len = (int)([line length] - startPos);
                for (int i = (int) startPos; i < len; i++) {
                    NSString *character = [line substringWithRange: NSMakeRange(i, 1)];
                    if ([character isEqualToString:@"]"]) {
                        keyline = [keyline stringByAppendingString:@"\n"];
                        break;
                    }
                    keyline = [keyline stringByAppendingString:character];
                }
            }
        }
        if ([line hasPrefix:@"M:"]) {
            metrumLine = [line stringByAppendingString:@"\n"];
        }
        if ([line hasPrefix:@"L:"]) {
            lengthLine = [line stringByAppendingString:@"\n"];
        }
    }
    NSString *writeFile = [NSString stringWithFormat:@"%@", abcCode];
    if (![writeFile hasPrefix:@"X:"]) {
        //only part of abc-Code, so add header
        removeHeader = YES;
        writeFile = [[[[@"X:1\n" stringByAppendingString:lengthLine] stringByAppendingString:metrumLine] stringByAppendingString:[NSString stringWithFormat: @"%@%@", keyline, [NSString stringWithFormat:@"%@",(noKeyFromVoice) ? [NSString stringWithFormat:@"[%@]",[keyline substringToIndex:keyline.length-1]] : @""]]] stringByAppendingString:abcCode];
    }
    NSLog(@"writing file: \n%@", writeFile);
    if (![writeFile writeToFile:tmpFile atomically:YES encoding:_encoding error:&error]) {
        NSLog(@"couldn't write tempFile to tranpose: %@, %@", error.localizedDescription, error.localizedFailureReason);
    }
    else {
        char *transp = strdup([@"-t" UTF8String]);
        char *transpose = strdup([[NSString stringWithFormat:@"%ld", (long)((transposition < 12) ? (transposition-12)*-1 : (transposition - 11)*-1)] UTF8String]);
        char *open = strdup([@"-o" UTF8String]);
        char *noErr = strdup([@"-e" UTF8String]);
        char *duppedInPath = strdup([tmpFile UTF8String]);
        gatherTranspose = YES;
        _transposedString = @"";
        fileprogram = ABC2ABC;
        NSString *totalTransCode = @"";
        char *args[] = {open, duppedInPath, noErr, transp, transpose, NULL };
        abc2abcMain(5, args);
        if (error) {
            NSLog(@"Couldn't read transposed tempFile: %@", error.localizedFailureReason);
        }
        else {
            NSMutableArray *transLines = [_transposedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
            NSString *transCode = @"";
            for (int i = (int)transLines.count-1; i >= 0; i--) {
                if (i < transLines.count) {
                    NSString *line = transLines[i];
                    if ([line isEqualToString:@""] )
                        [transLines removeObject:line];
                    else if ([line hasPrefix:@"V:"]) {
                        transCode = [[NSString stringWithFormat:@"%@\n", voices[voices.count-1]] stringByAppendingString:transCode];
                        [voices removeLastObject];
                    }
                    else if (![transCode hasPrefix:line])
                        transCode = [[NSString stringWithFormat:@"%@\n", line] stringByAppendingString:transCode];
                }
                else
                    transCode = @"";
            }
            transCode = [regex stringByReplacingMatchesInString:transCode options:0 range:NSMakeRange(0, [transCode length]) withTemplate:@"\n"];
            _logString = [[[@"Transposed:\n\n" stringByAppendingString:_transposedString] stringByAppendingString:@"\n\n"] stringByAppendingString:_logString];
            [self setMutableLogString];
            if (!_logEnabled) {
                _logEnabled = YES;
                [_logSwitch setOn:YES];
                [self enableLog:_logSwitch];
            }
            if (!removeHeader) {
                NSLog(@"TRANSPOSED CODE:\n%@", transCode);
                totalTransCode = [totalTransCode stringByAppendingString:transCode];
            }
            else {
                transCode = @"";
                for (int i = (int)transLines.count-1; i > 0; i--) {
                    if (i < transLines.count) {
                        NSString *line = transLines[i];
                        if ((i < 4 && ([line hasPrefix:@"X:"] || [line hasPrefix:@"L:"] || [line hasPrefix:@"M:"] || [line hasPrefix:@"K:"])))
                            [transLines removeObject:line];
                        else transCode = [[NSString stringWithFormat:@"%@\n", line] stringByAppendingString:transCode];
                    }
                }
                totalTransCode = [totalTransCode stringByAppendingString:[[transCode substringToIndex:transCode.length-1] stringByAppendingString:[NSString stringWithFormat:@"%@", (!noKeyFromVoice) ? @"" : [NSString stringWithFormat:@"[%@]", [keyline substringToIndex:keyline.length-1]]]]];
            }
        }
        if (removeHeader) {
            NSString *replaceTotalTransCode = [_abcView.textView.text stringByReplacingOccurrencesOfString:abcCode withString:totalTransCode];
            totalTransCode = replaceTotalTransCode;
        }
        [self setColouredCodeFromString:totalTransCode];
        gatherTranspose = NO;
        [self render];
    }
}

- (void) transpose: (NSString *) menuController {
    if (pickershown)
        return;
    else pickershown = YES;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Transpose:" message:@"\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    NSArray *transpositions = @[@"12", @"11", @"10", @"9", @"8", @"7", @"6", @"5", @"4", @"3", @"2", @"1", @"-1", @"-2", @"-3", @"-4", @"-5", @"-6", @"-7", @"-8", @"-9", @"-10", @"-11", @"-12", ];
    _instrumentsPicker = [[arrayPicker alloc] initWithArray:transpositions frame:CGRectMake(40, 50, 200, 80) andTextColour:[UIColor brownColor]];
    [alertController.view addSubview:_instrumentsPicker.pickerView];
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"transpose" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSInteger transpositionNumber = [self->_instrumentsPicker.pickerView selectedRowInComponent:0];
        [self performTransposition:transpositionNumber];
        pickershown = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        pickershown = NO;
    }];
    [_instrumentsPicker.pickerView selectRow:10 inComponent:0 animated:NO];
    [alertController addAction:selectAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL) canPerformAction:(SEL)action withSender:(id)sender {
    UITextRange *selectedRange = [_abcView.textView selectedTextRange];
    NSString *paste = [UIPasteboard generalPasteboard].string;
    BOOL selected = [_abcView.textView textInRange:selectedRange].length > 0;
    if ((action == @selector(copy:)) & selected || (action == @selector(cut:)) & selected || (action == @selector(select:)) & !selected || (action == @selector(selectAll:)) & !selected || (action == @selector(paste:)) & (paste.length > 0) ||  (action == @selector(transpose:)) & selected || action == @selector(changeProgram:inRange:) || action == @selector(changeControl:inRange:) ||  action == @selector(changeDrummap:inRange:)) {
        return YES;
    }
    else return NO;
}

BOOL decorationController;

- (void) enterSpecialKeyFromBarButtonItem: (UIBarButtonItem*) item {
    if ([item.title isEqualToString:@"undo"]) {
        [_abcView.textView.undoManager undo];
    }
    else if ([item.title isEqualToString:@"redo"]) {
        [_abcView.textView.undoManager redo];
    }
    else if ([item.title isEqualToString:@"decorations"] || [item.title isEqualToString:@"dynamics"] || [item.title isEqualToString:@"structure"] || [item.title isEqualToString:@"directives"]) {
        if (!_decorations) {
            _decorations = [NSMutableArray array];
        }
        else [_decorations removeAllObjects];
        NSError *error = nil;
        NSString *decos = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", item.title] ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"couldn't read decorationsFile: %@", error.localizedFailureReason);
        }
        NSArray *lines = [decos componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            if (![line isEqualToString:@""]) {
                NSArray *split = [line componentsSeparatedByString:@";"];
                [_decorations addObject:split];
            }
        }
        decorationController = YES;
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", item.title] message:@"chose to insert." preferredStyle:UIAlertControllerStyleAlert];
        UIViewController *controller = [self controllerWithTableViewEditable:NO];
        [actionSheet setValue:controller forKey:@"contentViewController"];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
        [actionSheet addAction:cancel];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
    else {
        NSString *character = [[NSString alloc] initWithUTF8String:item.title.UTF8String];
        [_abcView.textView replaceRange:_abcView.textView.selectedTextRange withText:character];
    }
}

- (void)keyboardWillShow:(NSNotification*)notification {
    if (!alertShown) {
        NSDictionary *info = [notification userInfo];
        NSValue *keyBoardEndFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGSize keyboardSize = [keyBoardEndFrame CGRectValue].size;
        _keyboardHeight = keyboardSize.height;
        CGFloat keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        if (_displayHeight.constant + 28 > _keyboardHeight) {
            [UIView animateWithDuration:keyboardAnimationDuration*1.5 animations:^{
                float height = self->_displayHeight.constant *1.2 - self->_keyboardHeight;
                self->_displayHeight.constant = height;
                self->_webDisplayView.frame = CGRectMake(self->_webDisplayView.frame.origin.x, self->_webDisplayView.frame.origin.y, self->_webDisplayView.frame.size.width, height);
            }];
            buttonViewMoved = YES;
        }
        else {
            [UIView animateWithDuration:keyboardAnimationDuration*1.5 animations:^{
                CGPoint newContentOffset = CGPointMake(self->_abcView.textView.contentOffset.x, self->_abcView.textView.contentOffset.y + self->_keyboardHeight);
                [self->_abcView.textView setContentOffset:newContentOffset animated:YES];
            }];
        }_abcViewBottom.constant = _keyboardHeight + 2;
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];
    }
    _keyboard = YES;
}

BOOL buttonViewMoved;

- (void)keyboardWillHide:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *keyBoardEndFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [keyBoardEndFrame CGRectValue].size;
    _keyboardHeight = keyboardSize.height;
    if (_displayHeight.constant + _keyboardHeight < self.view.frame.size.height && buttonViewMoved) {
        CGFloat keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [UIView animateWithDuration:keyboardAnimationDuration*1.5 animations:^{
            float height = (self->_displayHeight.constant + self->_keyboardHeight) * 0.8;
            self->_displayHeight.constant = height;
            self->_webDisplayView.frame = CGRectMake(self->_webDisplayView.frame.origin.x, self->_webDisplayView.frame.origin.y, self->_webDisplayView.frame.size.width, height);
        }];
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];
        buttonViewMoved = NO;
    }
    _abcViewBottom.constant = 2;
    _keyboard = NO;
    _keyboardHeight = 0;
}

- (void) loadSvgImage {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:webFolder error:nil];
    NSString *imagePath = [_selectedVoice stringByAppendingPathExtension:@"svg"];
    int index = (int) [directory indexOfObject:imagePath];
    if (index == -1 && directory.count > 1)
        index = 1;
    else if (index == -1)
        return;
    NSString *filePath = [webFolder stringByAppendingPathComponent:directory[index]];
    _exportFile = [NSURL fileURLWithPath:filePath];
    [_webDisplayView loadFileURL:_exportFile allowingReadAccessToURL:[NSURL fileURLWithPath:webFolder]];
    
}

- (void) setColouredCodeFromString: (NSString*) code {
    NSMutableAttributedString *string;
    if (_codeHighlighting) {
        
        string = [[NSMutableAttributedString alloc]initWithString:code];
        NSArray *lines = [code componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            __block BOOL quote = NO;
            __block BOOL marked = NO;
            if ([line hasPrefix:@"V:"]) {
                //voices
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
            }
            else if ([line hasPrefix:@"w:"] || [line hasPrefix:@"W:"]) {
                //lyrics
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:range];
            }
            else if ([line hasPrefix:@"%%score"] || [line hasPrefix:@"%%staves"]) {
                //here we grab the parts to display
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor magentaColor] range:range];
            }
            else if ([line hasPrefix:@"%%"]) {
                //format attributes
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor brownColor] range:range];
            }
            else if ([line hasPrefix:@"%"]) {
                //comments
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];
            }
            else if (line.length > 0) [code enumerateSubstringsInRange:[code rangeOfString:line]
                                     options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                                         if ([substring isEqualToString:@"|"] || [substring isEqualToString:@"]"] || [substring isEqualToString:@"["]) {
                                             [string addAttribute:NSForegroundColorAttributeName value: [UIColor greenColor] range:substringRange];
                                         }
                                         BOOL dequote = NO;
                                         if ([substring isEqualToString:@"\""]) {
                                             quote = !quote;
                                             dequote = YES;
                                         }
                                         if (quote || dequote) {
                                             [string addAttribute:NSForegroundColorAttributeName value: [UIColor blueColor] range:substringRange];
                                         }
                                         BOOL demark = NO;
                                         if ([substring isEqualToString:@"!"]) {
                                             marked = !marked;
                                             demark = YES;
                                         }
                                         if (marked || demark) {
                                             [string addAttribute:NSForegroundColorAttributeName value: [UIColor orangeColor] range:substringRange];
                                         }
                                     }];
        }
    }
    [_abcView.textView setScrollEnabled:NO];
    NSRange cursorPosition = _abcView.textView.selectedRange;
    if (_codeHighlighting) {
        [_abcView.textView setAttributedText:string];
    }
    else {
        _abcView.textView.textColor = [UIColor darkGrayColor];
        _abcView.textView.text = code;
    }
    _abcView.textView.font = [UIFont systemFontOfSize:_fontSize];
    [_abcView.textView setSelectedRange:cursorPosition];
    [_abcView setTintColor:[UIColor whiteColor]];
    [_abcView.textView setScrollEnabled:YES];
}

- (NSMutableArray*) getVoicesWithHeader {
    NSMutableArray *allTunes = [NSMutableArray array];
    if (!_directMode) {
        NSArray* allLinedStrings = [_abcView.textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSMutableArray *header = [NSMutableArray array];
        BOOL headerRead = false;
        NSString *currentVoice;
        NSMutableArray *currentVoiceString = [NSMutableArray array];
        NSMutableArray *allVoices = [NSMutableArray array];
        NSMutableArray *totalVoices = [NSMutableArray array];
        NSMutableArray *userScoresAndStaves = [NSMutableArray array];
        NSMutableArray *totalUserScoresAndStaves = [NSMutableArray array];
        NSMutableArray *combinedVoicesWithName = [NSMutableArray array];
        NSString *tuneTitle;
        BOOL tuneRead = NO;
        for (int i = 0 ; i < allLinedStrings.count; i++) {
            NSString *line = allLinedStrings[i];
            BOOL lastLine = (i == allLinedStrings.count-1);
            //        lastLine = [line isEqualToString:[allLinedStrings lastObject]];
            tuneRead = (lastLine || ((line.length > 2 && [[line substringToIndex:2] isEqualToString:@"X:"]) && ![line isEqualToString:[allLinedStrings firstObject]]));
            if (line.length > 2 && ![[line substringToIndex:2] isEqualToString:@"V:"] && !headerRead) {
                [header addObject: line];
                if ((line.length > 10) && [[line substringToIndex:8] isEqualToString:@"%%staves"])
                    [userScoresAndStaves addObject:line];
                if ((line.length > 9) && [[line substringToIndex:7] isEqualToString:@"%%score"])
                    [userScoresAndStaves addObject:line];
            }
            else {
                if (line.length > 2 && [[line substringToIndex:2] isEqualToString:@"V:"]){
                    if (![line isEqualToString:currentVoice]) {
                        headerRead = true;
                        if (currentVoiceString.count > 0 && currentVoice != nil) {
                            NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
                            [allVoices addObject:voice];
                            [totalVoices addObject:voice];
                        }
                        currentVoice = line;
                        [currentVoiceString removeAllObjects];
                    }
                }
                [currentVoiceString addObject:line];
            }
            if (tuneRead) {
                NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
                tuneTitle = voice[3];
                [allVoices addObject:voice];
                [totalVoices addObject:voice];
                BOOL multi = (allTunes.count > 0 && lastLine);
                if (!multi)
                    combinedVoicesWithName = [self combineVoicesFromUserScoresAndStaves:userScoresAndStaves forArray:allVoices forMultiFile:NO];
                if (combinedVoicesWithName.count < 1) {
                    _potentialVoices = [NSMutableArray array];
                    for (NSArray *voice in allVoices) {
                        [_potentialVoices addObject:voice[0]];
                    }
                }
                [allTunes addObject:@[tuneTitle, [combinedVoicesWithName mutableCopy]]];
                [currentVoiceString removeAllObjects];
                [totalUserScoresAndStaves addObject:[userScoresAndStaves mutableCopy]];
                headerRead = false;
                [header removeAllObjects];
                [userScoresAndStaves removeAllObjects];
                [allVoices removeAllObjects];
                tuneRead = false;
            }
            if (lastLine && allTunes.count > 1) {
                combinedVoicesWithName = [self combineVoicesFromUserScoresAndStaves:totalUserScoresAndStaves forArray:totalVoices forMultiFile:YES];
                [allTunes removeAllObjects];
                NSString *name = [_filepath lastPathComponent];
                [allTunes addObject:@[[name substringToIndex:name.length-4], [combinedVoicesWithName mutableCopy]]];
            }
        }
    }
    else {
        // read from abctextView
        [allTunes removeAllObjects];
        NSString *name = [_filepath lastPathComponent];
        [allTunes addObject:@[[name substringToIndex:name.length-4], [@[@[[name substringToIndex:name.length-4], [NSString stringWithString:_abcView.textView.text]]] mutableCopy]]];
        
    }
    return allTunes;
}

- (NSMutableArray*) combineVoicesFromUserScoresAndStaves: (NSMutableArray*) userScoresAndStaves forArray: (NSMutableArray*) allVoices forMultiFile: (BOOL) multifile {
    NSMutableArray *combinedVoicesWithName = [NSMutableArray array];
    NSMutableArray *scoresAndStaves = [NSMutableArray array];
    NSString *string = @"";
    NSArray *getStaveOrScoreName = [[NSArray alloc] init];
    NSString *staveOrScoreName = @"";
    NSString *staveOrScoreVoices = @"";
    NSArray *stavesOrScoreOptions = [[NSArray alloc] init];
    BOOL usualWriting = NO;
    if (multifile) {;
        for (NSArray *ma in userScoresAndStaves) {
            BOOL dobreak = NO;
            for (NSString *new in ma) {
                getStaveOrScoreName = [new componentsSeparatedByString:@"%"];
                staveOrScoreName = [getStaveOrScoreName lastObject];
                stavesOrScoreOptions = [staveOrScoreName componentsSeparatedByString:@" "];
                if (![scoresAndStaves containsObject:staveOrScoreName]) {
                    if ([staveOrScoreName hasPrefix:@"staves"] || [staveOrScoreName hasPrefix:@"score"]) {
                        usualWriting = YES;
                        NSCharacterSet *delete = [NSCharacterSet characterSetWithCharactersInString:@"{}()[]"];
                        staveOrScoreName = [[staveOrScoreName componentsSeparatedByCharactersInSet: delete] componentsJoinedByString: @""];
                        [scoresAndStaves addObject:staveOrScoreName];
                        NSArray *wantedVoices = [staveOrScoreName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        for (int i = 1; i < wantedVoices.count; i++) {
                            [scoresAndStaves addObject:wantedVoices[i]];
                        }
                        staveOrScoreVoices = staveOrScoreName;
                        dobreak = YES;
                        break;
                    }
                    else [scoresAndStaves addObject:new];
                }
            }
            if (dobreak)
                break;
        }
    }
    for (int i = 0; i < ((!multifile) ? userScoresAndStaves.count : scoresAndStaves.count); i++) {
        NSString *filename = [[_filepath path] lastPathComponent];
        if (!multifile) {
            string = userScoresAndStaves[i];
        }
        else {
            string = scoresAndStaves[i];
        }
        getStaveOrScoreName = [string componentsSeparatedByString:@"%"];
        staveOrScoreName = [getStaveOrScoreName lastObject];
        stavesOrScoreOptions = [staveOrScoreName componentsSeparatedByString:@" "];
        if (stavesOrScoreOptions.count >= 1) {
            staveOrScoreName = stavesOrScoreOptions[0];
            if ([staveOrScoreVoices isEqualToString:@""])
                staveOrScoreVoices = (getStaveOrScoreName.count > 1) ? getStaveOrScoreName[getStaveOrScoreName.count-2] : staveOrScoreName;
        }
        if (usualWriting || [staveOrScoreVoices isEqualToString:@""]) staveOrScoreVoices = string;
        NSString *combinedVoices = @"";
        if (getStaveOrScoreName.count > 0) {
            NSString *keepTitle = @"";
            for (int j = 0; j < allVoices.count; j++) {
                NSArray *array = allVoices[j];
                if (j == 0) {
                    NSString *headerToModify = array[1];
                    int incept = (int) [headerToModify rangeOfString:@"\n"].location;
                    combinedVoices = [[[headerToModify substringToIndex:incept] stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]] stringByAppendingString:[headerToModify substringFromIndex:incept]];
                    combinedVoices = [[[headerToModify substringToIndex:incept] stringByAppendingString:[NSString stringWithFormat:@"\n%@", [string stringByAppendingString:(multifile) ? @"\n\%\%keywarn 0" : @""]]] stringByAppendingString:[headerToModify substringFromIndex:incept]];
                    if (multifile) {
                        NSArray *Header = [combinedVoices componentsSeparatedByString:@"\n"];
                        for (NSString *line in Header) {
                            if ([line hasPrefix:@"T:"]) {
                                combinedVoices = [combinedVoices stringByReplacingOccurrencesOfString:line withString:[NSString stringWithFormat:@"T:%@", [filename substringToIndex:filename.length-4]]];
                                break;
                            }
                        }
                    }
                    if (stavesOrScoreOptions.count > 1) {
                        for (int k = 1; k < stavesOrScoreOptions.count; k++) {
                            NSString *option = stavesOrScoreOptions[k];
                            NSArray *optionSep = [option componentsSeparatedByString:@"="];
                            if (optionSep.count != 2) {
                                break;
                            }
                            else combinedVoices = [combinedVoices stringByAppendingString:[[@"\n%%" stringByAppendingString:optionSep[0]] stringByAppendingString:[NSString stringWithFormat:@" %@", optionSep[1]]]];
                        }
                    }
                }
                NSString *name = array[0];
                if ([staveOrScoreVoices rangeOfString:name].location != NSNotFound) {
                    if (multifile) {
                        //add new title and stuff
                        NSArray *newHeader = [array[1] componentsSeparatedByString:@"\n"];
                        for (NSString *line in newHeader) {
                            if ([line hasPrefix:@"T:"] && ![[line substringFromIndex:2] isEqualToString:keepTitle]) {
                                combinedVoices = [combinedVoices stringByAppendingString:[@"\n" stringByAppendingString: line]];
                                keepTitle = [line substringFromIndex:2];
                            }
                            NSCharacterSet *fields = [NSCharacterSet characterSetWithCharactersInString:@"COAGPZNGHRBDSFI"];
                            if ([[line substringToIndex:2] rangeOfCharacterFromSet:fields].location != NSNotFound) {
                                combinedVoices = [combinedVoices stringByAppendingString:[@"\n" stringByAppendingString: line]];
                            }
                            NSCharacterSet *inlineFields = [NSCharacterSet characterSetWithCharactersInString:@"KLM"];
                            if ([[line substringToIndex:2] rangeOfCharacterFromSet:inlineFields].location != NSNotFound) {
                                combinedVoices = [combinedVoices stringByAppendingString:[NSString stringWithFormat:@"\n[%@]", line]];
                            }
                        }
                    }
                        combinedVoices = [combinedVoices stringByAppendingString:[@"\n" stringByAppendingString: array[2]]];
//                        NSLog(@"ADDED LINE:\n%@\nTO VOICE:%@ \nVOICESTRING:\n\n%@", array[2], staveOrScoreVoices, combinedVoices);
                }
            }
        }
        NSString *voiceName = [NSString stringWithFormat:@"%@_%@", [filename substringToIndex:filename.length-4], staveOrScoreName];
        if (multifile)
            NSLog(@"created Voice %@: \n\n%@", voiceName, combinedVoices);
        [combinedVoicesWithName addObject:@[voiceName, combinedVoices]];
        staveOrScoreVoices = @"";
    }
    return combinedVoicesWithName;
}

- (NSArray*) voiceStringWithNameFromCleanedHeader:(NSMutableArray*) header withData: (NSMutableArray*) currentVoiceString {
    
    NSString *cleanedHeader = header[0];
    NSArray *voiceInfo = [currentVoiceString[0] componentsSeparatedByString:@" "];
    NSString *name = [voiceInfo[0] substringFromIndex:2];
    NSString *title = @"";
    for (int i = 1; i < header.count; i++) {
        NSString *line = header[i];
        if ([line hasPrefix:@"T:"])
            title = [line substringFromIndex:2];
        if (line.length < 8) {
            cleanedHeader = [cleanedHeader stringByAppendingString:[NSString stringWithFormat:@"\n%@", line]];
        }
        else if (!([[line substringToIndex:8] isEqualToString:@"%%staves"]) && !([[line substringToIndex:7] isEqualToString:@"%%score"])) {
            cleanedHeader = [cleanedHeader stringByAppendingString:[NSString stringWithFormat:@"\n%@", line]];
        }
    }
    NSString *voice = currentVoiceString[0];
    for (int i = 1; i < currentVoiceString.count; i++) {
        NSString *voiceLine = currentVoiceString[i];
        if ([voiceLine isEqualToString:@""])
            break;
        voice = [voice stringByAppendingString:[NSString stringWithFormat:@"\n%@", voiceLine]];
    }
    return @[name, cleanedHeader, voice, title];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)moveHorizontalStack:(UIPanGestureRecognizer *)sender {
    if (!_skipping) {
        float yLoc = [sender locationInView:self.view].y;
        if ( yLoc < 28 || yLoc > self.view.frame.size.height-28) {
            return;
        }
        else {
            float height = yLoc - _logHeight.constant;
            if (height >= self.view.frame.size.height -_keyboardHeight - ((_buttonViewExpanded) ? 169 : 40))
                return;
            _displayHeight.constant = height;
            _webDisplayView.frame = CGRectMake(_webDisplayView.frame.origin.x, _webDisplayView.frame.origin.y, _webDisplayView.frame.size.width, height);
        }
    }
    else {
        float skipper = [sender locationInView:self.view].x / self.view.frame.size.width;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endSkip) object: nil];
        [self performSelector:@selector(endSkip) withObject:nil afterDelay:0.5];
        [_mp skip:skipper];
    }
}

- (void) endSkip {
    _skipping = NO;
}

- (IBAction)toggleLogExpansion:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        [self->_logSwitch setOn: NO];
    }];
    [self enableLog:_logSwitch];
}

- (IBAction)expandLog:(UIPanGestureRecognizer *)sender {
    _logHeight.constant = [sender locationInView:self.view].y;
}

- (IBAction)buttonViewSizeToggle:(id)sender {
    _buttonViewExpanded = !_buttonViewExpanded;
    _buttonViewHeight.constant = (_buttonViewExpanded) ? 153 : 24;
    [UIView animateWithDuration:0.3 animations:^{
        self->_sfButton.hidden = !self->_buttonViewExpanded;
        self->_playButton.hidden = !self->_buttonViewExpanded;
        self->_skipControl.hidden = !self->_buttonViewExpanded;
        self->_serverLabel.hidden = !self->_buttonViewExpanded;
        self->_serverSwitch.hidden = !self->_buttonViewExpanded;
        self->_exportButton.hidden = !self->_buttonViewExpanded;
        self->_logSwitchLabel.hidden = !self->_buttonViewExpanded;
        self->_logSwitch.hidden = !self->_buttonViewExpanded;
        self->_codeHighlightingLabel.hidden = !self->_buttonViewExpanded;
        self->_codeHighlightingSwitch.hidden = !self->_buttonViewExpanded;
        self->_playbackProgress.hidden = !self->_buttonViewExpanded;
        self->_autoRefreshLabel.hidden = !self->_buttonViewExpanded;
        self->_autoRefreshSwitch.hidden = !self->_buttonViewExpanded;
        self->_codeAssistLabel.hidden = !self->_buttonViewExpanded;
        self->_codeAssistSwitch.hidden = !self->_buttonViewExpanded;
        [self.view layoutIfNeeded];
        self->_displayHeight.constant = self->_buttonsView.frame.origin.y-6;
        self->_webDisplayView.frame = CGRectMake(self->_displayView.frame.origin.x-2, self->_displayView.frame.origin.y-4, self->_displayView.frame.size.width, self->_displayView.frame.size.height);
    }];
}

- (NSString *) stringWithContentsOfEncodedFile: (NSString *) file {
    NSString *content = @"";
    NSError *error = nil;
    content = [NSString stringWithContentsOfFile:file  encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        error = nil;
        content = [NSString stringWithContentsOfFile:file  encoding:NSASCIIStringEncoding error:&error];
        if (error != nil) {
            error = nil;
            content = [NSString stringWithContentsOfFile:file  encoding:NSUnicodeStringEncoding error:&error];
            if (error != nil) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"could not read file" message:[NSString stringWithFormat:@"unknown encoding of file: : %@", error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else _encoding = NSUnicodeStringEncoding;
        }
        else _encoding = NSASCIIStringEncoding;
    }
    else _encoding = NSUTF8StringEncoding;
    if (!error) {
        content = [content stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
        content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    }
    return content;
}

- (void) loadABCfileFromPath: (NSString*) path {
    
    _filepath = [NSURL fileURLWithPath:path];
#if TARGET_OS_MACCATALYST
    _filepath = [NSURL fileURLWithPath:[docsPath stringByAppendingPathComponent:[_filepath lastPathComponent]]];
#endif
    NSString *content = @"";
    content = [self stringWithContentsOfEncodedFile:path];
    if (![content isEqualToString:@""]) {
        [self setColouredCodeFromString:content];
        
        [_allVoices removeAllObjects];
        _allVoices = [self getVoicesWithHeader];
    }
    if (_allVoices.count < 1) {
        [_webDisplayView loadHTMLString:@"" baseURL:nil];
        return;
    }
    NSArray *tune = _allVoices[0];
    NSMutableArray *tuneArray = tune[1];
    _tuneTitle = tune[0];
    if (tuneArray.count > 0) {
        [_voiceSVGpaths createVoices:tuneArray];
        NSArray *voice = tuneArray[0];
        _selectedVoice = voice[0];
        [self loadSvgImage];
    }
}

- (BOOL) enterFullScoreAndOrParts {
    NSArray *tune = _allVoices[0];
    NSMutableArray *tuneArray = tune[1];
    if (tuneArray.count < 1) {
        if ([_abcView.textView.text isEqualToString:@""]) {
            return NO;
        }
        NSArray *buttons = [NSArray arrayWithObjects:@"create full score only", @"create parts only", @"create full score and parts", nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"no rule to create parts or a full score found!" message:@"choose to add full score, parts or both:" preferredStyle:UIAlertControllerStyleAlert];
        for (NSString *title in buttons) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                NSString *addFullScore = @"\n%%score ";
                NSString *addParts = @"";
                for (NSString *name in self->_potentialVoices) {
                    addFullScore = [addFullScore stringByAppendingString:[NSString stringWithFormat:@"%@ ", name]];
                    NSString *part = @"\n%%staves ";
                    addParts = [addParts stringByAppendingString:[[part stringByAppendingString:[NSString stringWithFormat:@"%@ ", name]] stringByAppendingString:[@"%" stringByAppendingString:[NSString stringWithFormat:@"%@ scale=0.7 barsperstaff=8", name]]]];
                }
                addFullScore = [addFullScore stringByAppendingString:@"%Partitur scale=0.6 barsperstaff=4"];
                NSMutableString *orig = [NSMutableString stringWithString:self->_abcView.textView.text];
                NSRange location = [orig rangeOfString:@"\n"];
                NSString *inserted = [[[[orig substringToIndex:location.location] stringByAppendingString:([title isEqualToString:@"create full score only"] || [title isEqualToString:@"create full score and parts"]) ? addFullScore : @"" ] stringByAppendingString:([title isEqualToString:@"create parts only"] || [title isEqualToString:@"create full score and parts"]) ? addParts : @""] stringByAppendingString:[orig substringFromIndex:location.location]];
                [self setColouredCodeFromString:inserted];
                [self->_allVoices removeAllObjects];
                self->_allVoices = [self getVoicesWithHeader];
                NSArray *tune = self->_allVoices[0];
                NSMutableArray *tuneArray = tune[1];
                [self->_voiceSVGpaths createVoices:tuneArray];
                self->_tuneTitle = tune[0];
                NSArray *Voice = tuneArray[0];
                self->_selectedVoice = Voice[0];
                [self loadSvgImage];
            }];
            [alert addAction:action];
        }
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    else return NO;
}


- (IBAction)buttonPressed:(UIButton *)sender {
    if (sender.tag == 0) {
        _midiCreated = NO;
        [self load];
    }
    else if (sender.tag == 1) {
        [self store];
    }
    else if (sender.tag == 2) {
        [self display];
    }
    else if (sender.tag == 3) {
        [self render];
    }
    else if (sender.tag == 4) {
        //create new file:
        [self createNewFile];
    }
}

- (NSMutableArray*) updateTuneArray {
    NSError *error = nil;
    _tuneArray = [NSMutableArray array];
    NSMutableArray *abcDocuments = [NSMutableArray array];
    NSString *filecontent = [NSString stringWithContentsOfURL:_filepath encoding:_encoding error:&error];
    if (!error) {
        NSArray* tunes = [filecontent componentsSeparatedByString:@"\nX:"];
        for (int i = 0; i < tunes.count; i++) {
            NSString *tune = tunes [i];
            //extract title
            NSArray *tunelines = [tune componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            for (NSString *line in tunelines) {
                if (line.length > 4 && [line hasPrefix:@"T:"]) {
                    NSString *title = [line substringFromIndex:2];
                    [abcDocuments addObject:title];
                    break;
                }
            }
            if (i == 0) {
                NSArray *tuneData = @[tune, [NSValue valueWithRange:[filecontent rangeOfString:tune]], abcDocuments[i]];
                [_tuneArray addObject:tuneData];
            }
            else {
                NSArray *tuneData = @[[@"X:" stringByAppendingString:tune], [NSValue valueWithRange:[filecontent rangeOfString:tune]], abcDocuments[i]];
                [_tuneArray addObject:tuneData];
            }
        }
    }
    return abcDocuments;
}

UIAlertController *alert;
BOOL alertShown;

- (void) createNewFile {
    dropCreate = 1;
    _createFilePopup = [self createPopupcontrollerWithIdentifier:@"createNewFileController"];
    [_createFilePopup presentInViewController:self];
}

- (STPopupController *) createPopupcontrollerWithIdentifier: (NSString*) identifier {
    STPopupController *controller = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName: @"Main" bundle:nil] instantiateViewControllerWithIdentifier:identifier]];
    controller.containerView.layer.cornerRadius = 16;
    [controller setNavigationBarHidden:YES];
    if (NSClassFromString(@"UIBlurEffect")) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        controller.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        controller.backgroundView.alpha = 0.9;
    }
    [controller.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dropPopup)]];
    return controller;
}

float dropCreate;

- (void) dropPopup {
//    createFileViewController *pop = (createFileViewController*) [_createFilePopup topViewController];
//    [pop disMiss:nil];
    if (dropCreate == 1) {
        [_createFilePopup dismiss];
        _createFilePopup = nil;
    }
    else if (dropCreate == 0) {
        [_loadFilePopup dismiss];
        _loadFilePopup = nil;
    }
    else {
        [_exportPopup dismiss];
        _exportPopup = nil;
        
    }
}

- (IBAction)zoomText:(UIPinchGestureRecognizer *)sender {
    float scale = ((sender.scale <=2) ? sender.scale : 2) - 1;
    _fontSize = _abcView.textView.font.pointSize + (scale * 0.5);
    _abcView.textView.font = [UIFont systemFontOfSize:_fontSize];
    _abcView.textView.lineNumberFont = [UIFont systemFontOfSize:_fontSize*0.7];
    if (_logEnabled) {
        _logView.font = [UIFont systemFontOfSize:_fontSize];
    }
}

- (IBAction)startHTTPserver:(UISwitch *)sender {
    if (sender.isOn) {
        if(![self.server start]) {
            [_serverSwitch setOn:NO];
            return;
        }
        [self performSelector:@selector(updateServerLabel) withObject:self afterDelay:1.0];
    }
    else {
        [self.server stop];
        _serverLabel.text = @"start http-server";
    }
}

- (IBAction)codeHighlightingEnabled:(UISwitch*)sender {
    _codeHighlighting = sender.isOn;
    [self setColouredCodeFromString:_abcView.textView.text];
    _codeHighlightingLabel.text = (_codeHighlighting) ? @"abc-code highlighting enabled" : @"enable abc-code highlighting";
}

- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

-(void) updateServerLabel {
    [self.serverLabel setText: [NSString stringWithFormat:@"connect to: http://%@.local:%d or %@:%d", self.server.hostName, self.server.port, [self getIPAddress], self.server.port]];
}
- (IBAction)hideKeyboard:(id)sender {
    [_abcView endEditing:YES];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: (!decorationController) ? UITableViewCellStyleDefault : UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    if (!decorationController) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Default";
        }
        else cell.textLabel.text = _userSoundfonts[indexPath.row-1];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
    }
    else {
        cell.textLabel.font=[UIFont boldSystemFontOfSize:10];
        cell.detailTextLabel.font=[UIFont systemFontOfSize:5];
        NSArray *decor = _decorations[indexPath.row];
        cell.textLabel.text = decor[0];
        cell.detailTextLabel.text = decor[1];
    }
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!decorationController) {
        return _userSoundfonts.count + 1;
    }
    else return _decorations.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!decorationController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            _mp = nil;
            NSString *sfFile = [[NSString alloc] init];
            if (indexPath.row == 0) {
                sfFile = [[NSBundle mainBundle] pathForResource:@"32MbGMStereo" ofType:@"sf2" inDirectory:@"DefaultFiles"];
            }
            else sfFile = [docsPath stringByAppendingPathComponent: _userSoundfonts[indexPath.row-1]];
        [self loadSoundfontAtPath:(NSString *) sfFile];
    }
    else {
        NSArray *split = _decorations[indexPath.row];
        [_abcView.textView replaceRange:_abcView.textView.selectedTextRange withText:split[0]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) loadSoundfontAtPath: (NSString*) sfFile {
    _soundfontUrl = [[NSURL alloc] initFileURLWithPath:sfFile];
    _mp = [[midiPlayer alloc] initWithSoundFontURL:_soundfontUrl];
    _mp.progressView = _playbackProgress;
    _mp.delegate = self;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent: _userSoundfonts[indexPath.row-1]];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        }
        else {
            [self loadSf2Documents];
            if (_userSoundfonts.count == 0) {
                [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
            [tableView reloadData];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!decorationController && indexPath.row > 0) 
        return YES;
    else
        return NO;
}

- (IBAction)exportMIDI:(UIButton*) sender andPlay: (BOOL) play {
    if (sender == nil || !sender.isSelected ) {
        play = sender != nil;
        _midiCreated = YES;
        //delete old midi files
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray *directory = [fileManager contentsOfDirectoryAtPath:docsPath error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.mid'"];
        NSArray *array = [directory filteredArrayUsingPredicate:fltr];
        for (NSString *file in array) {
            NSError *error;
            BOOL success = [fileManager removeItemAtPath:[docsPath stringByAppendingPathComponent:file] error:&error];
            if (!success) {
                NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
            }
        }
        //    create the new one
        NSString *inPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[_selectedVoice stringByAppendingPathExtension:@"abc"]];
        NSString *filename = [[[inPath lastPathComponent] substringToIndex:[inPath lastPathComponent].length-4] stringByAppendingPathExtension:@"mid"];
        NSString *outFile = [NSString stringWithFormat:@"%@", [[docsPath stringByAppendingPathComponent:@"webDAV"] stringByAppendingPathComponent: filename]];
        char *open = strdup([@"-o" UTF8String]);
        const char *outPath = strdup([outFile UTF8String]);
        char *duppedOut = strdup(outPath);
        char *duppedInPath = strdup([inPath UTF8String]);
        char *args[] = {open, duppedInPath, open, duppedOut, NULL };
        gatherTranspose = NO;
        fileprogram = ABC2MIDI;
        abc2midiMain(4, args);
        
        if (_mp == nil) {
            _mp = [[midiPlayer alloc] initWithSoundFontURL:_soundfontUrl];
            _mp.delegate = self;
            _mp.progressView = _playbackProgress;
        }
        _midiFile = [[NSURL alloc] initFileURLWithPath:outFile];
        if (play) {
            [_mp loadMidiFileFromUrl:_midiFile];
            [_mp startMidiPlayer];
            
            _playButton.selected = YES;
        }
    }
    else {
        [_mp stopMidiPlayer];
        _playButton.selected = NO;
        _mp = nil;
    }
}

- (void) midiPlayerReachedEnd:(midiPlayer *)player {
    if (_playButton.isSelected) {
        _playButton.selected = NO;
        _mp = nil;
    }
}

- (void) loadSf2Documents {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:docsPath error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sf2'"];
    _userSoundfonts = [directory filteredArrayUsingPredicate:fltr];
}

- (UIViewController *) controllerWithTableViewEditable: (BOOL) editable {
    
    UIViewController *controller = [[UIViewController alloc]init];
    UITableView *alertTableView;
    CGRect rect;
    if (_userSoundfonts.count < 4) {
        rect = CGRectMake(0, 0, 272, 100);
        [controller setPreferredContentSize:rect.size];
        
    }
    else if (_userSoundfonts.count < 6){
        rect = CGRectMake(0, 0, 272, 150);
        [controller setPreferredContentSize:rect.size];
    }
    else if (_userSoundfonts.count < 8){
        rect = CGRectMake(0, 0, 272, 200);
        [controller setPreferredContentSize:rect.size];
        
    }
    else {
        rect = CGRectMake(0, 0, 272, 250);
        [controller setPreferredContentSize:rect.size];
    }
    
    alertTableView  = [[UITableView alloc]initWithFrame:rect];
    alertTableView.delegate = self;
    alertTableView.dataSource = self;
    alertTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    [alertTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [controller.view addSubview:alertTableView];
    [controller.view bringSubviewToFront:alertTableView];
    [controller.view setUserInteractionEnabled:YES];
    [alertTableView setUserInteractionEnabled:YES];
    [alertTableView setAllowsSelection:YES];
    [alertTableView setEditing:editable];
    alertTableView.allowsSelectionDuringEditing = YES;
    
    return controller;
}

- (IBAction)loadUserSoundFont:(id)sender {
    
    #if TARGET_OS_MACCATALYST
    [self openInCatalystWithDocType:@"com.soundblaster.soundfont"];
    #else
    decorationController = NO;
    [self loadSf2Documents];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"load soundfont-Tune:" message:@"to use your own sf2-files put them in the apps Shared Folder with iTunes." preferredStyle:UIAlertControllerStyleAlert];
    UIViewController *controller = [self controllerWithTableViewEditable:YES];
    [alert setValue:controller forKey:@"contentViewController"];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    #endif
}

int printf(const char * __restrict format, ...) {
    va_list args;
    va_start(args,format);
    ViewController *controller =  (ViewController*) APP.window.rootViewController;
    [controller logText:[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args]];
    va_end(args);
    return 1;
}

BOOL gatherTranspose;

- (void) logText:(NSString *)log {
    if (gatherTranspose) {
        _transposedString = [_transposedString stringByAppendingString:log];
    }
    else {
        NSLog(@"redirected printf: %@", log);
        _logString = [log stringByAppendingString:[NSString stringWithFormat:@"%@", _logString]];
        NSArray *lines = [_logString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if (lines.count > 999) {
            NSString *cut = @"";
            for (int i = (int) lines.count - 50; i < lines.count; i++) {
                cut = [cut stringByAppendingString:[NSString stringWithFormat:@"\n%@", lines[i]]];
            }
            _logString = cut;
        }
        if (_logEnabled) {
            if (setLogString) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endSkip) object: nil];
            }
            [self performSelector:@selector(setMutableLogString) withObject:nil afterDelay:0.2];
            setLogString = YES;
        }
    }
}

- (void) setMutableLogString {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc]initWithString:_logString];
    NSArray *lines = [_logString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"error"]) {
            //voices
            NSRange range=[_logString rangeOfString:line];
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
        }
        else if ([line hasPrefix:@"warning"] || [line hasPrefix:@"Warning"]) {
                //voices
                NSRange range=[_logString rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
            }
    }
    [_logView setAttributedText:string];
    _logView.font = [UIFont systemFontOfSize:_fontSize];
    setLogString = NO;
}

BOOL setLogString;

- (IBAction)enableLog:(UISwitch*)sender {
    _logEnabled = sender.isOn;
    _logSwitchLabel.text = _logEnabled ? @"log enabled" :  @"enable log";
    [UIView animateWithDuration:0.5 animations:^{
        self->_logHeight.constant = self->_logEnabled ? 80 : 0;
        if (self->_logEnabled) {
            [self setMutableLogString];
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!self->_logEnabled) {
                self->_logView.text = @"";
        }
    }];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (_codeHighlighting) {
        [self setColouredCodeFromString:_abcView.textView.text];
    }
    if (autoRefresh)
        [self render];
}

- (IBAction)exportDocument:(id)sender {
    dropCreate = 2;
    _exportPopup = [self createPopupcontrollerWithIdentifier:@"exportFileController"];
    [_exportPopup presentInViewController:self];
}

- (IBAction)clearLog:(id)sender {
    _logString = @"";
    if (_logEnabled) {
        [self setMutableLogString];
    }
}

- (IBAction)skip:(UISegmentedControl *)sender {
    _skipping = YES;
    [_mp skip:sender.selectedSegmentIndex-1];
}

- (void) createMailComposerWithDataArray: (NSArray *) dataArray {
    
    NSOperationQueue *_queue = [[NSOperationQueue alloc] init];
    [_queue addOperationWithBlock: ^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            [picker setSubject:@"abConduct-sheet"];
            for (NSArray *attach in dataArray) {
                [picker addAttachmentData:attach[0] mimeType:@"application/abConduct" fileName:attach[1]];
            }
            [picker setToRecipients:[NSArray array]];
            [picker setMessageBody:@"Hi,\nThis sheet is an export of the awesome abConduct_iOS-app" isHTML:NO];
            [picker setMailComposeDelegate:self];
            [self presentViewController:picker animated:YES completion:nil];
            //                }
            
        }];
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) shareExportDataArray: (NSArray *) dataArray {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:dataArray applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToTwitter, UIActivityTypeSaveToCameraRoll, UIActivityTypeMail, UIActivityTypePostToWeibo];
    NSLog(@"Shared Files: %@", dataArray);
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void) display {
    //        if (!_directMode) {
    dropCreate = 0;
    _loadFilePopup = [self createPopupcontrollerWithIdentifier:@"loadNewFileController"];
    loadFileViewController *loadFile = (loadFileViewController *) _loadFilePopup.topViewController;
    loadFile.loadController = NO;
    if (_tuneSelected != -1) {
        loadFile.loadTunes = YES;
        loadFile.multiTuneFile = [_filepath path];
    }
    [loadFile load];
    [_loadFilePopup presentInViewController:self];
}

- (void) load {
    //load
    #if TARGET_OS_MACCATALYST
    [self openInCatalystWithDocType:@"public.alembic"];
    #else
    dropCreate = 0;
    _loadFilePopup = [self createPopupcontrollerWithIdentifier:@"loadNewFileController"];
    loadFileViewController *loadFile = (loadFileViewController *) _loadFilePopup.topViewController;
    loadFile.loadController = YES;
    if (_tuneSelected != -1  || _unselectedMultitune) {
        loadFile.loadTunes = YES;
        loadFile.multiTuneFile = [_filepath path];
    }
    [loadFile load];
    [_loadFilePopup presentInViewController:self];
    #endif
}

-(void) openInCatalystWithDocType: (NSString*) docType {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[docType]
                                                                                                            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    documentPicker.allowsMultipleSelection = NO;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

//mac catalyst import
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(nonnull NSArray<NSURL *> *)urls {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSURL *url = urls[0];
        NSString *path = [url path];
        if ([[path substringFromIndex:[path length]-4] isEqualToString:@".abc"]) {
            [self loadABCfileFromPath:path];
            _refreshButton.enabled = YES;
            _saveButton.enabled = YES;
        }
        else [self loadSoundfontAtPath:path];
    }
}

- (void) store {
    //store
    if (_tuneSelected == -1) {
        NSError *error;
        BOOL write = [_abcView.textView.text writeToURL:_filepath atomically:NO encoding:_encoding error:&error];
        if (!write) {
            write = [_abcView.textView.text writeToURL:_filepath atomically:NO encoding:NSUTF8StringEncoding error:&error];
            if (!write) {
                NSLog(@"could not write file: %@", error);
            }
        }
        else {
            _refreshButton.enabled = YES;
            _saveButton.enabled = YES;
        }
    }
    else {
        //merge textView content into File
        NSError *error;
        NSString *oldFileContent = [NSString stringWithContentsOfURL:_filepath encoding:_encoding error:&error];
        if (!error) {
            NSArray *replaceTune = _tuneArray[_tuneSelected];
            NSValue *rangeObject = replaceTune[1];
            NSRange range = rangeObject.rangeValue;
            range.location = range.location-2;
            range.length = range.length+2;
            NSString *newFileContent = [oldFileContent stringByReplacingCharactersInRange:range withString:_abcView.textView.text];
            if (![newFileContent writeToURL:_filepath atomically:YES encoding:_encoding error:&error])
                NSLog(@"couldn't write newFileContent: %@", error.localizedFailureReason);
            else [self updateTuneArray];
        }
        else NSLog(@"couldn't read multituneFile: %@", error.localizedFailureReason);
    }
    
#if TARGET_OS_MACCATALYST
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Want to export?" message:[NSString stringWithFormat:@"%@ stored to app's sandbox. Want to export?", [_filepath lastPathComponent]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exportAction = [UIAlertAction actionWithTitle:@"export" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURL:self->_filepath inMode:UIDocumentPickerModeExportToService];
        documentPicker.delegate = self;
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:documentPicker animated:YES completion:nil];
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No, thanks" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:exportAction];
    [alertController addAction:noAction];
    [self presentViewController:alertController animated:YES completion:nil];
#endif
}

- (void) storeText {
    [_saveButton setHighlighted:YES];
    [self store];
    [_saveButton setHighlighted:NO];
}

- (void) renderText {
    [_refreshButton setHighlighted:YES];
    [self render];
    [_refreshButton setHighlighted:NO];
}

- (void) transpose {
    [self transpose:nil];
}

- (void) loadDocument {
    [self load];
}

- (void) newDocument {
    [self createNewFile];
}

- (void) displayDocument {
    [self display];
}

- (void) exportDocument {
    [self exportDocument:nil];
}

- (void) playBack {
    [self exportMIDI:_playButton andPlay:YES];
}

- (void) render {
    //refresh
    _allVoices = [self getVoicesWithHeader];
    if (_allVoices.count < 1) {
        [_webDisplayView loadHTMLString:@"" baseURL:nil];
        return;
    }
    if (_tuneSelected < 0) {
        NSArray *tune = self->_allVoices[0];
        NSMutableArray *tuneArray = tune[1];
        [_voiceSVGpaths createVoices:tuneArray];
    }
    else {
        NSString *currentTune = [NSTemporaryDirectory() stringByAppendingPathComponent:@"currentTune.abc"];
        NSError *error;
        if (![_abcView.textView.text writeToFile:currentTune atomically:YES encoding:NSUTF8StringEncoding error:&error])
            NSLog(@"couldn't write currentTune to file: %@", error.localizedFailureReason);
        else {
            NSURL *keepMultifile = _filepath;
            [self loadABCfileFromPath:currentTune];
            _filepath = keepMultifile;
        }
    }
    if (![self enterFullScoreAndOrParts])
        [self loadSvgImage];
    else [_webDisplayView loadHTMLString:@"" baseURL:nil];
}

- (IBAction)toggleCodeAssistant:(id)sender {
    codeAssist = _codeAssistSwitch.isOn;
    _codeAssistLabel.text = (codeAssist) ? @"abc-Code assisted" : @"assist abc-Code";
}

- (IBAction)toggleAutoRefresh:(id)sender {
    autoRefresh = _autoRefreshSwitch.isOn;
    _autoRefreshLabel.text = (autoRefresh) ? @"auto-refresh enabled" : @"enable auto-refresh";
}

BOOL autoRefresh, codeAssist;


- (void) dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session  API_AVAILABLE(ios(11.0)){
    [session loadObjectsOfClass:([NSURL self]) completion: ^(NSArray *urls) {
        for (NSURL *url in urls) {
            NSLog(@"url of dragItem: %@", url.absoluteString);
        }
    }];
    for (UIDragItem *item in session.items) {
        if ([[item.itemProvider.suggestedName substringFromIndex:item.itemProvider.suggestedName.length-4] isEqualToString:@".abc"]) {
            [item.itemProvider loadItemForTypeIdentifier:@"public.alembic" options:nil completionHandler:^(NSURL *url, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [APP openUrl:url];
                });
            }];
        }
    }
}

- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session  API_AVAILABLE(ios(11.0)){
    return [session hasItemsConformingToTypeIdentifiers:@[@"public.alembic"]];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session  API_AVAILABLE(ios(11.0)){
    UIDropProposal *proposal = [[UIDropProposal alloc] initWithDropOperation: UIDropOperationCopy];
    return proposal;
 }

@end

