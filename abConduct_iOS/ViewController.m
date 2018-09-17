//
//  ViewController.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property NSURL *filepath;
@property NSMutableArray *allVoices;
@property BOOL buttonViewExpanded;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *file = [[NSBundle mainBundle] pathForResource:@"Hallelujah" ofType:@"abc" inDirectory: @"DefaultFiles"];
    _filepath = [NSURL fileURLWithPath:file];
    NSString *content = [NSString stringWithContentsOfFile:[_filepath path]  encoding:NSUTF8StringEncoding error:NULL];
    NSMutableAttributedString *colouredCode = [self colouredCodeFromString:content];
    [_abcView setAttributedText:colouredCode];
    _allVoices = [NSMutableArray array];
    _allVoices = [self getVoicesWithHeader];
    NSString *pdfFile = [[NSBundle mainBundle] pathForResource:@"Hallelujah_Partitur" ofType:@"pdf" inDirectory: @"DefaultFiles"];
    _displayView.displayMode = kPDFDisplaySinglePageContinuous;
    _displayView.displayDirection = kPDFDisplayDirectionHorizontal;
    [self loadPdfFromFilePath:pdfFile];
}

- (void) loadPdfFromFilePath: (NSString*) filpath {
    NSURL *file = [NSURL fileURLWithPath:filpath];
    PDFDocument *pdf = [[PDFDocument alloc] initWithURL:file];
    _displayView.document = pdf;
    _displayView.maxScaleFactor = 4.0;
    _displayView.minScaleFactor = _displayView.scaleFactorForSizeToFit;
    _displayView.autoScales = true;
}

- (NSMutableAttributedString *) colouredCodeFromString: (NSString*) code {
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc]initWithString:code];
    NSArray *lines = [code componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"V:"]) {
            NSRange range=[code rangeOfString:line];
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
        }
        else if ([line hasPrefix:@"w:"]) {
                NSRange range=[code rangeOfString:line];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
        }
    }
    return string;
}

- (NSMutableArray*) getVoicesWithHeader {
    NSArray* allLinedStrings = [_abcView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
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
        [combinedVoicesWithName addObject:@[staveOrScoreName, combinedVoices]];
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

- (IBAction)buttonViewSizeToggle:(id)sender {
    _buttonViewExpanded = !_buttonViewExpanded;
    _buttonViewHeight.constant = (_buttonViewExpanded) ? 150 : 24;;
}

- (IBAction)buttonPressed:(UIButton *)sender {
    if (sender.tag == 0) {
        //load
    }
    else if (sender.tag == 1) {
            //store
    }
    else if (sender.tag == 2) {
        //display
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"display voice" message:@"choose the voice to display" preferredStyle:UIAlertControllerStyleAlert];
        for (NSArray *voice in _allVoices) {
            NSString *voiceName = voice[0];
            UIAlertAction *action = [UIAlertAction actionWithTitle:voiceName style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                NSLog(@"display voice: %@", voice);
                NSString *fileName = [[self->_filepath lastPathComponent] substringToIndex:[self->_filepath lastPathComponent].length-4];
                [self loadPdfFromFilePath:[[NSBundle mainBundle] pathForResource:[fileName stringByAppendingString:[NSString stringWithFormat:@"_%@", voiceName]] ofType:@"pdf" inDirectory: @"DefaultFiles"]];
            }];
            [alert addAction:action];
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (sender.tag == 3) {
        //refresh
    }
}

- (IBAction)zoomText:(UIPinchGestureRecognizer *)sender {
    NSLog(@"scale: %f", sender.scale);
    float scale = ((sender.scale <=2) ? sender.scale : 2) - 1;
    CGFloat size = _abcView.font.pointSize + (scale * 0.5);
    _abcView.font = [UIFont systemFontOfSize:size];
}

@end
