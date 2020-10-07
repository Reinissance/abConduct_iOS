//
//  exportViewController.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 04.03.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import "exportViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
#import "voiceHandler.h"

#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define controller ((ViewController *)[[(AppDelegate*)APP window] rootViewController])

@interface exportViewController ()

@end

@implementation exportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)exportSwitchesSwitched:(UISwitch *)sender {
    if (sender.tag == 1 && sender.isOn) {
        [_exportAllSwitch setOn:NO];
    }
    if (sender.tag == 2 && sender.isOn) {
        [_exportCurrentSwitch setOn:NO];
    }
    float exportable = _exportABCSwitch.on + _exportCurrentSwitch.on + _exportAllSwitch.on + _exportMIDISwitch.on;
    _exportButton.enabled = exportable;
    _shareButton.enabled = exportable;
}


- (IBAction)createMailButtonPushed:(id)sender {
    NSMutableArray *exportArray = [NSMutableArray array];
    if (_exportABCSwitch.isOn) {
        [exportArray addObject:@[[NSData dataWithContentsOfFile:[controller.filepath path]], [[controller.filepath path] lastPathComponent]]];
    }
    if (_exportCurrentSwitch.isOn) {
        [exportArray addObject:@[[NSData dataWithContentsOfFile:[controller.exportFile path]], [[controller.exportFile path] lastPathComponent]]];
    }
    else if (_exportAllSwitch.isOn) {
        for (NSString *filePath in controller.voiceSVGpaths.voicePaths) {
            NSURL *url = [NSURL fileURLWithPath:[[docsPath stringByAppendingPathComponent:@"webDAV"] stringByAppendingPathComponent: filePath]];
            [exportArray addObject:@[[NSData dataWithContentsOfFile:[url path]], [[url path] lastPathComponent]]];
        }
    }
    if (_exportMIDISwitch.isOn) {
        if (!controller.midiCreated) {
            [controller exportMIDI:nil andPlay:NO];
        }
        [exportArray addObject:@[[NSData dataWithContentsOfFile:[controller.midiFile path]], [[controller.midiFile path] lastPathComponent]]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [controller createMailComposerWithDataArray:exportArray];
    }];
}

- (IBAction)shareButtonPushed:(id)sender {
    
    NSMutableArray *exportArray = [NSMutableArray array];
    if (_exportABCSwitch.isOn) {
        [exportArray addObject:[NSURL fileURLWithPath: [controller.filepath path]]];
    }
    if (_exportCurrentSwitch.isOn) {
        [exportArray addObject:[NSURL fileURLWithPath:[controller.exportFile path]]];
    }
    else if (_exportAllSwitch.isOn) {
        for (NSString *filePath in controller.voiceSVGpaths.voicePaths) {
            NSURL *url = [NSURL fileURLWithPath:[[docsPath stringByAppendingPathComponent:@"webDAV"] stringByAppendingPathComponent: filePath]];
            [exportArray addObject:url];
        }
    }
    if (_exportMIDISwitch.isOn) {
        if (!controller.midiCreated) {
            [controller exportMIDI:nil andPlay:NO];
        }
        [exportArray addObject:[NSURL fileURLWithPath:[controller.midiFile path]]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [controller shareExportDataArray:exportArray];
    }];
}

@end
