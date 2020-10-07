//
//  loadFileViewController.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 01.03.19.
//  Copyright © 2019 Reinhard Sasse. All rights reserved.
//

#import "loadFileViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"

#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define controller ((ViewController *)[[(AppDelegate*)APP window] rootViewController])

@interface loadFileViewController ()

@end

@implementation loadFileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    _tuneTitle = @"";
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _abcDocuments = [NSMutableArray array];
    
}

-(void) load {
    if (_loadController) {
        //loadFile
        if (_loadTunes) {
            for (NSArray *tune in controller.tuneArray) {
                [_abcDocuments addObject:tune[2]];
            }
            [_abcDocuments addObject:@"<<< all abc-Tunes"];
            _titleLabel.text = @"select tune";
            NSString *name = [controller.filepath lastPathComponent];
            _messageLabel.text = [NSString stringWithFormat: @"multiple tunes found in file %@, you may wish to load only one?", name];
        }
        else {
            [self loadABCdocuments];
            [self setLoadTitle];
        }
    }
    else {
        //diplay Voices
        [self setDisplayTitle];
        if (controller.tuneSelected >= 0) {
            _messageLabel.text = [_messageLabel.text stringByAppendingString:[NSString stringWithFormat:@" for tune \"%@\"", controller.tuneTitle]];
            _tuneTitle = controller.tuneTitle;
        }
        if (!controller.directMode) {
            _abcDocuments = controller.voiceSVGpaths.voicePaths;
        }
        else {
            [self getVoicesForDirectMode];
        }
    }
}

- (void) getVoicesForDirectMode {
    _abcDocuments = [NSMutableArray array];
}

- (void) setDisplayTitle {
    _titleLabel.text = @" display voice:";
    _titleLabel.textColor = [UIColor magentaColor];
    _messageLabel.text = @"chose which voice you want to be displayed";
}

- (void) setLoadTitle {
    _titleLabel.text = @"load abc-Tune";
    _titleLabel.textColor = [UIColor blackColor];
    _messageLabel.text = @"to add tunes put them in the apps Shared Folder with iTunes.";
}


- (void) loadABCdocuments {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:docsPath error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.abc'"];
    _abcDocuments = [[directory filteredArrayUsingPredicate:fltr] mutableCopy];
    for (NSString *file in _abcDocuments) {
        if ([file containsString:@" "]) {
            NSError *error;
            if (![fileManager moveItemAtPath:[docsPath stringByAppendingPathComponent:file] toPath:[docsPath stringByAppendingPathComponent:[[file lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"]] error:&error])
                NSLog(@"couldn´t rename file: %@", error.localizedFailureReason);
            [self loadABCdocuments];
            break;
        }
    }
    _abcDocuments = [self checkMultiFile:_abcDocuments];
}

- (NSMutableArray *) checkMultiFile: (NSMutableArray *) array {
    NSMutableArray *checked = [NSMutableArray array];
    for (int i = 0; i < array.count; i++) {
        NSString *file = [docsPath stringByAppendingPathComponent:array[i]];
        NSError *error = nil;
        NSString *content = [controller stringWithContentsOfEncodedFile:file];
        if (![content isEqualToString:@""]) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\nX:" options:NSRegularExpressionCaseInsensitive error:&error];
            NSUInteger numberOfMatches = [regex numberOfMatchesInString:content options:0 range:NSMakeRange(0, [content length])];
            if (numberOfMatches > 0) {
                [checked addObject:[array[i] stringByAppendingString:@" >>>"]];
            }
            else [checked addObject:array[i]];
        }
        else NSLog(@"couldn`t check file: %@", file);
    }
    return checked;
}

- (void) getTunes: (NSString*) fileName {
    _abcDocuments = [controller updateTuneArray];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    NSString *title = _abcDocuments[indexPath.row];
    if ([title hasPrefix:@"currentTune_"]) {
        title = [title stringByReplacingOccurrencesOfString:@"currentTune" withString:_tuneTitle];
    }
    if (!_loadController) {
        title = [title substringToIndex:title.length-4];
    }
    cell.textLabel.text = title;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.textColor = ([[title substringFromIndex:title.length-4] isEqualToString:@" >>>"] || [[title substringToIndex:4] isEqualToString:@"<<< "]) ? [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5] : [UIColor blueColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _abcDocuments.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileName = _abcDocuments[indexPath.row];
    if (_loadController) {
        //load abcDocuments
        controller.refreshButton.enabled = YES;
        controller.saveButton.enabled = YES;
        controller.logString = @"";
        controller.tuneSelected = -1;
        if (!_loadTunes) {
            if (![[fileName substringFromIndex: fileName.length - 4] isEqualToString:@" >>>"]) {
                //no multifile
                controller.unselectedMultitune = NO;
                [controller loadABCfileFromPath:[docsPath stringByAppendingPathComponent:fileName]];
                [self dismissViewControllerAnimated:YES completion:^{
                    [controller enterFullScoreAndOrParts];
                }];
            }
            else {
                //switch to selectable tunes
                _loadTunes = YES;
                _multiTuneFile = [docsPath stringByAppendingPathComponent:[fileName substringToIndex:fileName.length-4]];
                [controller loadABCfileFromPath:_multiTuneFile];
                [controller enterFullScoreAndOrParts];
                controller.unselectedMultitune = YES;
                [self getTunes:_multiTuneFile];
                [_abcDocuments addObject:@"<<< all abc-Tunes"];
                _titleLabel.text = @"select tune";
                NSString *name = [fileName.lastPathComponent substringToIndex:fileName.lastPathComponent.length-4];
                _messageLabel.text = [NSString stringWithFormat: @"multiple tunes found in file %@, you may wish to load only one?", name];
                [_tableView setContentOffset:CGPointZero animated:YES];
                [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
        else if (indexPath.row == _abcDocuments.count-1) {
            // return to all documents
            controller.unselectedMultitune = NO;
            _loadTunes = NO;
            [self loadABCdocuments];
            [self setLoadTitle];
            [_tableView setContentOffset:CGPointZero animated:YES];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        }
        else {
            // tune selected from multitunefile
            controller.unselectedMultitune = NO;
            controller.tuneSelected = (int) indexPath.row;
            NSError *error;
            NSString *currentTune = [NSTemporaryDirectory() stringByAppendingPathComponent:@"currentTune.abc"];
            NSArray *tune = controller.tuneArray[indexPath.row];
            if (![tune[0] writeToFile:currentTune atomically:YES encoding:NSUTF8StringEncoding error:&error])
                NSLog(@"couldn't write currentTune to file: %@", error.localizedFailureReason);
            else {
                [controller loadABCfileFromPath:currentTune];
                [self dismissViewControllerAnimated:YES completion:^{
                    [controller enterFullScoreAndOrParts];
                    controller.filepath = [NSURL fileURLWithPath:self->_multiTuneFile];
                    NSArray *tuneLines = [tune[0] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    for (NSString *line in tuneLines) {
                        if ([line hasPrefix:@"T:"]) {
                            controller.tuneTitle = [line substringFromIndex:2];
                            self->_tuneTitle = [line substringFromIndex:2];
                            break;
                        }
                    }
                }];
            }
        }
    }
    else {
        //display voices
        if (!controller.directMode) {
            NSString *voice = controller.voiceSVGpaths.voicePaths[indexPath.row];
            controller.selectedVoice = [voice substringToIndex:voice.length-4];
            [controller loadSvgImage];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *excludeMulti = _abcDocuments[indexPath.row];
        excludeMulti = ([[excludeMulti substringFromIndex:excludeMulti.length-4] isEqualToString:@" >>>"]) ? [excludeMulti substringToIndex:excludeMulti.length-4] : excludeMulti;
        NSString *filePath = [documentsPath stringByAppendingPathComponent: excludeMulti];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        }
        if ([_abcDocuments[indexPath.row] isEqualToString:[controller.filepath lastPathComponent]]) {
            controller.abcView.textView.text = @"";
//                    [controller.displayView loadHTMLString:@"" baseURL:nil];
            controller.refreshButton.enabled = NO;
            controller.saveButton.enabled = NO;
        }
        [self loadABCdocuments];
        if (_abcDocuments.count == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        [tableView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_loadController) {
        if (!_loadTunes)
            return YES;
        else return NO;
    }
    else
        return NO;
}

@end
