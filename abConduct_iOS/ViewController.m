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
#import "voiceHandler.h"
#import "store.h"


#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface ViewController () {

}

@property NSURL *filepath;
@property NSMutableArray *allVoices;
@property NSString *selectedVoice;
@property voiceHandler *voiceSVGpaths;
@property BOOL buttonViewExpanded;
@property NSMutableArray *potentialVoices;
@property BOOL codeHighlighting;
@property arrayPicker *keyPicker;
@property arrayPicker *measurePicker;
@property NSArray *abcDocuments;
@property NSArray *userSoundfonts;
@property NSString *createFileName;
@property NSString *createFileComposer;
@property NSString *createFileLength;
@property midiPlayer *mp;
@property NSURL *soundfontUrl;
@property BOOL loadSFs;
@property BOOL logEnabled;
@property NSStringEncoding encoding;
@property NSString *logString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *file = [[NSBundle mainBundle] pathForResource:@"Hallelujah" ofType:@"abc" inDirectory: @"DefaultFiles"];
    _filepath = [NSURL fileURLWithPath:file];
    NSString *content = [NSString stringWithContentsOfFile:[_filepath path]  encoding:NSUTF8StringEncoding error:NULL];
    _logString = @"";
    _codeHighlighting = YES;
    [self setColouredCodeFromString:content];
    _allVoices = [NSMutableArray array];
    _allVoices = [self getVoicesWithHeader];
    _voiceSVGpaths = [[voiceHandler alloc] init];
    [_voiceSVGpaths createVoices:_allVoices];
    NSArray *voice = _allVoices[0];
    _selectedVoice = voice[0];
    [self loadSvgImage:voice[0]];
    self.server = APP.server;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    
    NSString *sfPath = [[NSBundle mainBundle] pathForResource:@"32MbGMStereo" ofType:@"sf2" inDirectory:@"DefaultFiles"];
    _soundfontUrl = [[NSURL alloc] initFileURLWithPath:sfPath];
    _encoding = NSUTF8StringEncoding;
    _abcView.textView.delegate = self;
    [_abcView.textView setTintColor:[UIColor whiteColor]];
    _abcView.textView.backgroundColor = [UIColor colorWithHue:41.0/360.0 saturation:11.0/360.0 brightness:84.0/360.0 alpha:0.0];
    _abcView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.window.frame.size.width, 44.0f)];
    toolBar.tintColor = [UIColor blackColor];
    toolBar.translucent = YES;
    toolBar.items =   @[[[UIBarButtonItem alloc] initWithTitle: @"|" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"/" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"^" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"_" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"=" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"-" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"." style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"," style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @":" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @">" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"<" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"(" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @")" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"!" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithTitle: @"\"" style:UIBarButtonItemStylePlain target:self action:@selector(enterSpecialKeyFromBarButtonItem:)],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         ];
    _abcView.textView.inputAccessoryView = toolBar;
}

- (void) enterSpecialKeyFromBarButtonItem: (UIBarButtonItem*) item {
    NSString *character = [[NSString alloc] initWithUTF8String:item.title.UTF8String];
    [_abcView.textView replaceRange:_abcView.textView.selectedTextRange withText:character];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    if (!alertShown) {
        CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        CGFloat keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        if (_displayHeight.constant + 25 > keyboardHeight) {
            [UIView animateWithDuration:keyboardAnimationDuration*1.5 animations:^{
                self->_displayHeight.constant = self->_displayHeight.constant - keyboardHeight;
                [self.view layoutIfNeeded];
            }];
        }
        else {
            CGPoint newContentOffset = CGPointMake(_abcView.textView.contentOffset.x, _abcView.textView.contentOffset.y + keyboardHeight);
            [_abcView.textView setContentOffset:newContentOffset animated:YES];
        }
        _abcView.frame = CGRectMake(_abcView.frame.origin.x, _abcView.frame.origin.y, _abcView.frame.size.width, _abcView.frame.size.height-keyboardHeight);
    }
}


- (void)keyboardWillHide:(NSNotification*)notification {
    CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    if (_displayHeight.constant + keyboardHeight < self.view.frame.size.height) {
        CGFloat keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [UIView animateWithDuration:keyboardAnimationDuration*1.5 animations:^{
            self->_displayHeight.constant = self->_displayHeight.constant + keyboardHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

- (void) loadSvgImage: (NSString*) image {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:webFolder error:nil];
    NSString *imagePath = [_selectedVoice stringByAppendingPathExtension:@"svg"];
    int index = (int) [directory indexOfObject:imagePath];
    NSURL *file = [NSURL fileURLWithPath:[webFolder stringByAppendingPathComponent:directory[index]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:file];
    [_displayView setScalesPageToFit:YES];
    [_displayView loadRequest:request];
}

- (void) setColouredCodeFromString: (NSString*) code {
    NSMutableAttributedString *string;
    if (_codeHighlighting) {
        
        string = [[NSMutableAttributedString alloc]initWithString:code];
        NSArray *lines = [code componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        __block BOOL quote = NO;
        for (NSString *line in lines) {
            if ([line hasPrefix:@"V:"]) {
                //voices
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
            }
            else if ([line hasPrefix:@"w:"]) {
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
                                         if ([substring isEqualToString:@"\""]) {
                                             quote = !quote;
                                         }
                                         if (quote) {
                                             [string addAttribute:NSForegroundColorAttributeName value: [UIColor blueColor] range:substringRange];
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
    [_abcView.textView setSelectedRange:cursorPosition];
    [_abcView setTintColor:[UIColor whiteColor]];
    [_abcView.textView setScrollEnabled:YES];
}

- (NSMutableArray*) getVoicesWithHeader {
    NSArray* allLinedStrings = [_abcView.textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *header = [NSMutableArray array];
    BOOL headerRead = false;
    NSString *currentVoice;
    NSMutableArray *currentVoiceString = [NSMutableArray array];
    NSMutableArray *allVoices = [NSMutableArray array];
    NSMutableArray *userScoresAndStaves = [NSMutableArray array];
    for (NSString *line in allLinedStrings) {
        if (line.length > 2 && ![[line substringToIndex:2] isEqualToString:@"V:"] && !headerRead) {
            [header addObject: line];
            if ((line.length > 10) && ([[line substringToIndex:8] isEqualToString:@"%%staves"] || [[line substringToIndex:7] isEqualToString:@"%%score"]))
                [userScoresAndStaves addObject:line];
        }
        else {
            if (line.length > 2 && [[line substringToIndex:2] isEqualToString:@"V:"]){
                if (![line isEqualToString:currentVoice]) {
                    headerRead = true;
                    if (currentVoiceString.count > 0 && currentVoice != nil) {
                        NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
                        [allVoices addObject:voice];
                    }
                    currentVoice = line;
                    [currentVoiceString removeAllObjects];
                }
            }
            [currentVoiceString addObject:line];
        }
    }
    NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
    [allVoices addObject:voice];
    NSMutableArray *combinedVoicesWithName = [NSMutableArray array];
    for (int i = 0; i < userScoresAndStaves.count; i++) {
        NSString *string = userScoresAndStaves[i];
        NSArray *getStaveOrScoreName = [string componentsSeparatedByString:@"%"];
        NSString *staveOrScoreName = [getStaveOrScoreName lastObject];
        NSArray *stavesOrScoreOptions = [staveOrScoreName componentsSeparatedByString:@" "];
        if (stavesOrScoreOptions.count > 1) {
            staveOrScoreName = stavesOrScoreOptions[0];
        }
        NSString *combinedVoices;
        if (getStaveOrScoreName.count > 0) {
            for (int j = 0; j < allVoices.count; j++) {
                NSArray *array = allVoices[j];
                if (j == 0) {
                    NSString *headerToModify = array[1];
                    int incept = (int) [headerToModify rangeOfString:@"\n"].location;
                    combinedVoices = [[[headerToModify substringToIndex:incept] stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]] stringByAppendingString:[headerToModify substringFromIndex:incept]];
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
                if ([string rangeOfString:name].location != NSNotFound) {
                    combinedVoices = [combinedVoices stringByAppendingString:[@"\n" stringByAppendingString: array[2]]];
                }
            }
        }
        NSString *filename = [[_filepath path] lastPathComponent];
        [combinedVoicesWithName addObject:@[[NSString stringWithFormat:@"%@_%@", [filename substringToIndex:filename.length-4], staveOrScoreName], combinedVoices]];
    }
    if (combinedVoicesWithName.count < 1) {
        _potentialVoices = [NSMutableArray array];
        for (NSArray *voice in allVoices) {
            [_potentialVoices addObject:voice[0]];
        }
    }
    return combinedVoicesWithName;
}

- (NSArray*) voiceStringWithNameFromCleanedHeader:(NSMutableArray*) header withData: (NSMutableArray*) currentVoiceString {
    
    NSString *cleanedHeader = header[0];
    NSArray *voiceInfo = [currentVoiceString[0] componentsSeparatedByString:@" "];
    NSString *name = [voiceInfo[0] substringFromIndex:2];
    for (int i = 1; i<header.count; i++) {
        NSString *line = header[i];
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
        voice = [voice stringByAppendingString:[NSString stringWithFormat:@"\n%@", voiceLine]];
    }
    return @[name, cleanedHeader, voice];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)moveHorizontalStack:(UIPanGestureRecognizer *)sender {
    if ( [sender locationInView:self.view].y < 23 || [sender locationInView:self.view].y > self.view.frame.size.height-24) {
        return;
    }
    else _displayHeight.constant = [sender locationInView:self.view].y;
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
    _buttonViewHeight.constant = (_buttonViewExpanded) ? 100 : 24;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void) loadABCfileFromPath: (NSString*) path {
    _filepath = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:[_filepath path]  encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        error = nil;
        content = [NSString stringWithContentsOfFile:[_filepath path]  encoding:NSASCIIStringEncoding error:&error];
        if (error != nil) {
            error = nil;
            content = [NSString stringWithContentsOfFile:[_filepath path]  encoding:NSUnicodeStringEncoding error:&error];
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
    if (error == nil) {
        content = [content stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
        content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        [self setColouredCodeFromString:content];
        
        [_allVoices removeAllObjects];
        _allVoices = [self getVoicesWithHeader];
    }
    if (_allVoices.count < 1) {
        [_displayView loadHTMLString:@"" baseURL:nil];
        return;
    }
    [_voiceSVGpaths createVoices:_allVoices];
    NSArray *voice = _allVoices[0];
    _selectedVoice = voice[0];
    [self loadSvgImage:_selectedVoice];
}

- (void) enterFullScoreAndOrParts {
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
        }];
        [alert addAction:action];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) loadABCdocuments {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:docsPath error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.abc'"];
    _abcDocuments = [directory filteredArrayUsingPredicate:fltr];
    for (NSString *file in _abcDocuments) {
        if ([file containsString:@" "]) {
            NSError *error;
            if (![fileManager moveItemAtPath:[docsPath stringByAppendingPathComponent:file] toPath:[docsPath stringByAppendingPathComponent:[[file lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"]] error:&error])
                NSLog(@"couldn´t rename file: %@", error.localizedFailureReason);
            [self loadABCdocuments];
        }
    }
}

- (IBAction)buttonPressed:(UIButton *)sender {
    if (sender.tag == 0) {
        //load
        _loadSFs = NO;
        [self loadABCdocuments];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"load abc-Tune:" message:@"to add tunes put them in the apps Shared Folder with iTunes." preferredStyle:UIAlertControllerStyleAlert];
        UIViewController *controller = [[UIViewController alloc]init];
        UITableView *alertTableView;
        CGRect rect;
        if (_abcDocuments.count < 4) {
            rect = CGRectMake(0, 0, 272, 100);
            [controller setPreferredContentSize:rect.size];
            
        }
        else if (_abcDocuments.count < 6){
            rect = CGRectMake(0, 0, 272, 150);
            [controller setPreferredContentSize:rect.size];
        }
        else if (_abcDocuments.count < 8){
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
        [alertTableView setEditing:YES];
        alertTableView.allowsSelectionDuringEditing = YES;
        [alert setValue:controller forKey:@"contentViewController"];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (sender.tag == 1) {
            //store
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
    else if (sender.tag == 2) {
        //display
        _allVoices = [self getVoicesWithHeader]; //refresh from input
        if (_allVoices.count < 1) {
            [self enterFullScoreAndOrParts];
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"display voice" message:@"choose the voice to display" preferredStyle:UIAlertControllerStyleAlert];
        for (NSArray *voice in _allVoices) {
            NSString *voiceName = voice[0];
            UIAlertAction *action = [UIAlertAction actionWithTitle:voiceName style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                self->_selectedVoice = voiceName;
                [self loadSvgImage:voiceName];
            }];
            [alert addAction:action];
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (sender.tag == 3) {
        //refresh
        _allVoices = [self getVoicesWithHeader];
        if (_allVoices.count < 1) {
            [_displayView loadHTMLString:@"" baseURL:nil];
            return;
        }
        [_voiceSVGpaths createVoices:_allVoices];
        [self loadSvgImage:_selectedVoice];
    }
    else if (sender.tag == 4) {
        //create new file:
        [self createNewFile];
    }
}

UIAlertController *alert;
BOOL alertShown;

- (void) createNewFile {
    _createFileComposer = @"";
    _createFileLength = @"";
    BOOL landscape = [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight;
    alert = [UIAlertController alertControllerWithTitle:@"create new abc-Code file:" message:(!landscape) ? @"please specify at least file-name (used as title) and key for your new tune.\n\n\n\n\n" :@"please specify at least the file-name (used as title) for your new tune (rotate device to change default key of 'C')\n" preferredStyle:UIAlertControllerStyleAlert];
    NSArray *Keys = @[@"C#", @"F#", @"B", @"E", @"A", @"D", @"G", @"C", @"F", @"Bb", @"Eb", @"Ab", @"Db", @"Gb"];
    _keyPicker = [[arrayPicker alloc] initWithArray:Keys frame:CGRectMake(30, 80, 100, 100) andTextColour:[UIColor redColor]];
    if (!landscape)
        [alert.view addSubview:_keyPicker.pickerView];
    NSArray *Measures = @[@"2/4", @"3/4", @"4/4", @"2/2", @"3/8", @"6/8", @"12/8", @"5/8", @"5/4", @"6/4", @"7/4", @"9/8", @"7/8"];
    _measurePicker = [[arrayPicker alloc] initWithArray:Measures frame:CGRectMake(140, 80, 100, 100) andTextColour:[UIColor darkTextColor]];if (!landscape)
    [alert.view addSubview:_measurePicker.pickerView];
    [_keyPicker.pickerView selectRow:7 inComponent:0 animated:NO];
    [_measurePicker.pickerView selectRow:2 inComponent:0 animated:NO];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull title) {
        UIColor *lightRed = [UIColor colorWithRed:256 green:0 blue:0 alpha:0.5];
        title.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"enter a file-name (title) here" attributes:@{NSForegroundColorAttributeName: lightRed}];
        title.clearButtonMode = UITextFieldViewModeWhileEditing;
        title.borderStyle = UITextBorderStyleRoundedRect;
        [title addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull composer) {
        composer.placeholder = @"enter composer name here";
        composer.clearButtonMode = UITextFieldViewModeWhileEditing;
        composer.borderStyle = UITextBorderStyleRoundedRect;
        [composer addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    alert.textFields[1].tag = 1;
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull noteLength) {
        noteLength.placeholder = @"enter default note length (L:1/8)";
        noteLength.clearButtonMode = UITextFieldViewModeWhileEditing;
        noteLength.borderStyle = UITextBorderStyleRoundedRect;
        noteLength.keyboardType = UIKeyboardTypeNumberPad;
        [noteLength addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    alert.textFields[2].tag = 2;
    UIAlertAction *create = [UIAlertAction actionWithTitle:@"create File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        BOOL extension = ((self->_createFileName.length > 4) && [[self->_createFileName substringFromIndex:self->_createFileName.length-4] isEqualToString:@".abc"]);
        NSString *createAbcFileString = [NSString stringWithFormat:@"X:1\nT:%@\n", (extension) ? [self->_createFileName substringToIndex:self->_createFileName.length-4] : self->_createFileName];
        if (![self->_createFileComposer isEqualToString:@""]) {
            createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"C:%@\n", self->_createFileComposer]];
        }
        if (![self->_createFileLength isEqualToString:@""]) {
            createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"L:%@\n", self->_createFileLength]];
        }
        createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"M:%@\n", Measures[[self->_measurePicker.pickerView selectedRowInComponent:0]]]];
        createAbcFileString = [createAbcFileString stringByAppendingString: [NSString stringWithFormat: @"K:%@\n", Keys[[self->_keyPicker.pickerView selectedRowInComponent:0]]]];
        NSLog(@"file created: %@", createAbcFileString);
        createAbcFileString = [createAbcFileString stringByAppendingString: @"V:Voice1\n\%start writing your tune here:\n"];
        [self setColouredCodeFromString: createAbcFileString];
        NSError *error;
        NSString *path = [docsPath stringByAppendingPathComponent:[self->_createFileName stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        if (!extension) {
            path = [path stringByAppendingPathExtension:@"abc"];
        }
        self->_filepath = [NSURL fileURLWithPath:path];
        BOOL write = [self->_abcView.textView.text writeToURL:self->_filepath atomically:NO encoding:self->_encoding error:&error];
        if (!write) {
            NSLog(@"could not write file %@: %@", self->_filepath, error);
        }
        else {
            self->_refreshButton.enabled = YES;
            self->_saveButton.enabled = YES;
        }
        [self cleanUpAlert];
    }];
    create.enabled = NO;
    [alert addAction:create];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self cleanUpAlert];
    }];
    [alert addAction:cancel];
    alertShown = YES;
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void) cleanUpAlert {
    _measurePicker = nil;
    _keyPicker = nil;
    alertShown = NO;
}

-(void)textDidChange:(UITextField *)textField {
    if (textField.tag == 0) {
        alert.actions[0].enabled = (textField.text.length > 0);
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
}

- (IBAction)zoomText:(UIPinchGestureRecognizer *)sender {
    float scale = ((sender.scale <=2) ? sender.scale : 2) - 1;
    CGFloat size = _abcView.textView.font.pointSize + (scale * 0.5);
    _abcView.textView.font = [UIFont systemFontOfSize:size];
    _abcView.textView.lineNumberFont = [UIFont systemFontOfSize:size*0.7];
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

-(void) updateServerLabel {
    [self.serverLabel setText: [NSString stringWithFormat:@"connect to: http://%@.local:%d", self.server.hostName, self.server.port]];
}
- (IBAction)hideKeyboard:(id)sender {
    [_abcView endEditing:YES];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
        [_measurePicker.pickerView removeFromSuperview];
        [_keyPicker.pickerView removeFromSuperview];
}

- (void)orientationChanged:(NSNotification *)notification{
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation {
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            if (alertShown) {
                [alert.view addSubview:_measurePicker.pickerView];
                [alert.view addSubview:_keyPicker.pickerView];
                alert.message = @"please specify at least file-name (used as title) and key for your new tune.\n\n\n\n\n";
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            [_keyPicker.pickerView removeFromSuperview];
            [_measurePicker.pickerView removeFromSuperview];
            alert.message = @"please specify at least the file-name (used as title) for your new tune (rotate device to change default key of 'C')\n";
        }            break;
        case UIInterfaceOrientationUnknown:break;
    }
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (!_loadSFs) {
        cell.textLabel.text = _abcDocuments[indexPath.row];
    }
    else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Default";
        }
        else cell.textLabel.text = _userSoundfonts[indexPath.row-1];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_loadSFs) {
        return _abcDocuments.count;
    }
    else return _userSoundfonts.count + 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_loadSFs) {
        [self dismissViewControllerAnimated:YES completion:nil];
        _refreshButton.enabled = YES;
        _saveButton.enabled = YES;
        NSString *fileName = _abcDocuments[indexPath.row];
        _logString = @"";
        [self loadABCfileFromPath:[docsPath stringByAppendingPathComponent:fileName]];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
        _mp = nil;
        NSString *sfFile = [[NSString alloc] init];
        if (indexPath.row == 0) {
            sfFile = [[NSBundle mainBundle] pathForResource:@"32MbGMStereo" ofType:@"sf2" inDirectory:@"DefaultFiles"];
        }
        else sfFile = [docsPath stringByAppendingPathComponent: _userSoundfonts[indexPath.row-1]];
        _soundfontUrl = [[NSURL alloc] initFileURLWithPath:sfFile];
        _mp = [[midiPlayer alloc] initWithSoundFontURL:_soundfontUrl];
        _mp.delegate = self;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:_abcDocuments[indexPath.row]];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        }
        else if (!_loadSFs) {
            [self loadABCdocuments];
            if (_abcDocuments.count == 0) {
                [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
            [tableView reloadData];
        }
//        else {
//            [self loadSf2Documents];
//            if (_userSoundfonts.count == 0) {
//                [self dismissViewControllerAnimated:YES completion:nil];
//                return;
//            }
//            [tableView reloadData];
//        }
    }
}

- (IBAction)exportMIDI:(UIButton*) sender {
    if (!sender.isSelected) {
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
        NSString *outFile = [NSString stringWithFormat:@"%@", [docsPath stringByAppendingPathComponent: filename]];
        char *open = strdup([@"-o" UTF8String]);
        const char *outPath = strdup([outFile UTF8String]);
        char *duppedOut = strdup(outPath);
        char *duppedInPath = strdup([inPath UTF8String]);
        char *args[] = {open, duppedInPath, open, duppedOut, NULL };
        abc2midiMain(4, args);
        
        if (_mp == nil) {
            _mp = [[midiPlayer alloc] initWithSoundFontURL:_soundfontUrl];
            _mp.delegate = self;
        }
        [_mp loadMidiFileFromUrl:[[NSURL alloc] initFileURLWithPath:outFile]];
        [_mp startMidiPlayer];
        
        _playButton.selected = YES;
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

- (IBAction)loadUserSoundFont:(id)sender {
    _loadSFs = YES;
    [self loadSf2Documents];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"load soundfont-Tune:" message:@"to use your own sf2-files put them in the apps Shared Folder with iTunes." preferredStyle:UIAlertControllerStyleAlert];
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
    [alertTableView setEditing:YES];
    alertTableView.allowsSelectionDuringEditing = YES;
    [alert setValue:controller forKey:@"contentViewController"];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

int printf(const char * __restrict format, ...) {
    va_list args;
    va_start(args,format);
    ViewController *controller =  (ViewController*) APP.window.rootViewController;
    [controller logText:[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args]];
    va_end(args);
    return 1;
}

- (void) logText:(NSString *)log {
    NSLog(@"redirected printf: %@", log);
    _logString = [log stringByAppendingString:[NSString stringWithFormat:@"%@", _logString]];
    NSArray *lines = [_logString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if (lines.count > 50) {
        NSString *cut = @"";
        for (int i = (int) lines.count - 50; i < lines.count; i++) {
            cut = [cut stringByAppendingString:[NSString stringWithFormat:@"\n%@", lines[i]]];
        }
        _logString = cut;
    }
    if (_logEnabled) {
        _logLabel.text = _logString;
    }
}

- (IBAction)enableLog:(UISwitch*)sender {
    _logEnabled = sender.isOn;
    _logSwitchLabel.text = _logEnabled ? @"log enabled" :  @"enable log";
    [UIView animateWithDuration:0.5 animations:^{
        self->_logHeight.constant = self->_logEnabled ? 80 : 0;
        if (self->_logEnabled) {
            self->_logLabel.text = self->_logString;
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!self->_logEnabled) {
                self->_logLabel.text = @"";
        }
    }];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (_codeHighlighting) {
        [self setColouredCodeFromString:_abcView.textView.text];
    }
}

@end
