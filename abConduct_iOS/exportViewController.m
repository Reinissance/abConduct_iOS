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
    float exportable = _exportABCSwitch.on + _exportCurrentSwitch.on + _exportAllSwitch.on;
    _exportButton.enabled = exportable;
}

- (IBAction)createMailButtonPushed:(id)sender {
//    NSData *data = [NSData dataWithContentsOfFile:controller.exportFile.path];
//                [picker addAttachmentData:data mimeType:@"application/abConduct" fileName:[[controller.exportFile path] lastPathComponent]];
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
    [self dismissViewControllerAnimated:YES completion:^{
        [controller createMailComposerWithDataArray:[exportArray copy]];
    }];
}
@end
