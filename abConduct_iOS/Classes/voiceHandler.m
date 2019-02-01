//
//  voiceHandler.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 02.10.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "voiceHandler.h"
#import "abcm2ps.h"

@implementation voiceHandler

NSFileManager *fileManager;

- (void) cleanTempFolder {
    if (!fileManager) {
        fileManager = [[NSFileManager alloc] init];
    }
    NSString *tmpDir = NSTemporaryDirectory();
    NSArray *wasDirectory = [fileManager contentsOfDirectoryAtPath:tmpDir error:nil];
    NSError *error;
    for (NSString *file in wasDirectory) {
        if (![fileManager removeItemAtPath:[tmpDir stringByAppendingPathComponent:file] error:&error]) {
            NSLog(@"couldn´t remove file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
        }
    }
}

- (void) createVoices:(NSMutableArray *)voices {
    if (self) {
        fileManager = [[NSFileManager alloc] init];
        [self cleanTempFolder];
        NSError *error;
        NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
        NSArray *wasWebDirectory = [fileManager contentsOfDirectoryAtPath:webFolder error:nil];
        for (NSString *file in wasWebDirectory) {
            if (![fileManager removeItemAtPath:[webFolder stringByAppendingPathComponent:file] error:&error]) {
                NSLog(@"couldn´t remove file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        NSString *tmpDir = NSTemporaryDirectory();
        for (NSArray *voice in voices) {
            if (![voice[1] writeToFile:[[tmpDir stringByAppendingPathComponent:voice[0]] stringByAppendingPathExtension:@"abc"] atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                NSLog(@"couln't write file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:webFolder])
            [[NSFileManager defaultManager] createDirectoryAtPath:webFolder withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"couldn't create webDAV-folder: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            return;
        }
        NSArray *isDirectory = [fileManager contentsOfDirectoryAtPath:tmpDir error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.abc'"];
        NSArray *voiceAbcFiles = [isDirectory filteredArrayUsingPredicate:fltr];
        _voicePaths = [NSMutableArray arrayWithCapacity:voiceAbcFiles.count];
        for (int i = 0; i < voiceAbcFiles.count; i++) {
            NSString *abcFile = voiceAbcFiles[i];
            [self createSVGFileFromFilePath:abcFile forArrayindex:i inDirectory:tmpDir];
        }
        [self createIndexHTML];
    }
}

- (void) createIndexHTML {
    NSError *error;
    NSString *createHTMLfile = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory: @"DefaultFiles"]  encoding:NSUTF8StringEncoding error:&error];
    NSString *tuneName = @"";
    NSString *files = @"";
    for (NSString *path in _voicePaths) {
        NSString *name = [path lastPathComponent];
        NSArray *nameAndVoice = [name componentsSeparatedByString:@"_"];
        if ([tuneName isEqualToString:@""]) {
            for (int i = 0; i < nameAndVoice.count-1; i++) {
                NSString *namePart = nameAndVoice[i];
                tuneName = [[tuneName stringByAppendingString:namePart] stringByAppendingString:@" "];
            }
        }
        NSString *voiceName = nameAndVoice[nameAndVoice.count-1];
        files = [[[files stringByAppendingString:@"<a href=\"/"] stringByAppendingString:name] stringByAppendingString:[NSString stringWithFormat:@"\">%@</a>\n</br>\n", voiceName]];
    }
    createHTMLfile = [[createHTMLfile stringByReplacingOccurrencesOfString:@"TITLENAME" withString:tuneName] stringByReplacingOccurrencesOfString:@"VOICELINKS" withString:files];
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
    if (![createHTMLfile writeToFile:[[webFolder stringByAppendingPathComponent:@"index"] stringByAppendingPathExtension:@"html"] atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"couldn't write indexHTML: %@, %@", error.localizedDescription, error.localizedFailureReason);
    }
}

- (void) createSVGFileFromFilePath: (NSString*) abcFile forArrayindex: (int) index inDirectory: (NSString*) dir {
    NSString *filename = [[abcFile substringToIndex:[abcFile lastPathComponent].length-4] stringByAppendingPathExtension:@"svg"];
    NSString *outFile = [NSString stringWithFormat:@"-O%@", filename];
    char *open = strdup([@"-O" UTF8String]);
    char *svg = strdup([@"-X" UTF8String]);
    const char *outPath = strdup([outFile UTF8String]);
    char *duppedOut = strdup(outPath);
    char *duppedSVG = strdup(svg);
    char *inPath = strdup([[dir stringByAppendingPathComponent: abcFile] UTF8String]);
    char *args[] = {open, duppedOut, duppedSVG, inPath, NULL };
    abcMain(4, args);
    [_voicePaths addObject: filename];
}

@end
