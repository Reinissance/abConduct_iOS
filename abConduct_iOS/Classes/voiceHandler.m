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
#import "ViewController.h"
#import "AppDelegate.h"

#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define docsPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define controller ((ViewController *)[[(AppDelegate*)APP window] rootViewController])

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
        //clean tempFolder
        [self cleanTempFolder];
        NSError *error;
        NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
        //clean webdavFolder
        NSArray *wasWebDirectory = [fileManager contentsOfDirectoryAtPath:webFolder error:nil];
        for (NSString *file in wasWebDirectory) {
            if (![fileManager removeItemAtPath:[webFolder stringByAppendingPathComponent:file] error:&error]) {
                NSLog(@"couldn´t remove file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        //create abcFiles in tempFolder
        NSString *tmpDir = NSTemporaryDirectory();
        for (NSArray *voice in voices) {
            if (![voice[1] writeToFile:[[tmpDir stringByAppendingPathComponent:voice[0]] stringByAppendingPathExtension:@"abc"] atomically:YES encoding:controller.encoding error:&error]) {
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
//        put abcFilePaths into voicePathsArray
        _voicePaths = [NSMutableArray arrayWithCapacity:voiceAbcFiles.count];
        //create svgFiles in tempDir
        for (int i = 0; i < voiceAbcFiles.count; i++) {
            NSString *abcFile = voiceAbcFiles[i];
            [self createSVGFileFromFilePath:abcFile forArrayindex:i inDirectory:tmpDir];
        }
        [self createIndexHTML];
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

//- (void) createSVGFileFromFilePath: (NSString*) abcFile forArrayindex: (int) index inDirectory: (NSString*) dir {
//    NSString *filename = [[abcFile substringToIndex:[abcFile lastPathComponent].length-4] stringByAppendingPathExtension:@"svg"];
//    NSString *outFile = [NSString stringWithFormat:@"-O%@", filename];
//    char *open = strdup([@"-O" UTF8String]);
//    char *svg = strdup([@"-X" UTF8String]);
//    char *sspref = strdup([@"--ss-pref %C" UTF8String]);
//    const char *outPath = strdup([outFile UTF8String]);
//    char *duppedOut = strdup(outPath);
//    char *duppedSVG = strdup(svg);
//    char *duppedSSpref = strdup(sspref);
//    char *inPath = strdup([[dir stringByAppendingPathComponent: abcFile] UTF8String]);
//    char *args[] = {open, duppedOut, duppedSVG, duppedSSpref, inPath, NULL };
//    abcMain(5, args);
//    [_voicePaths addObject: filename];
//}

- (void) createIndexHTML {
    NSError *error;
    NSString *createHTMLfile = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory: @"DefaultFiles"]  encoding:controller.encoding error:&error];
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
        if ([tuneName hasPrefix:@"currentTune"]) {
            tuneName = [tuneName stringByReplacingOccurrencesOfString:@"currentTune" withString:controller.tuneTitle];
        }
        NSString *voiceName = nameAndVoice[nameAndVoice.count-1];
        files = [[[files stringByAppendingString:@"<a href=\"/"] stringByAppendingString:name] stringByAppendingString:[NSString stringWithFormat:@"\">%@</a>\n</br>\n", voiceName]];
    }
    createHTMLfile = [[createHTMLfile stringByReplacingOccurrencesOfString:@"TITLENAME" withString:tuneName] stringByReplacingOccurrencesOfString:@"VOICELINKS" withString:files];
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
    if (![createHTMLfile writeToFile:[[webFolder stringByAppendingPathComponent:@"index"] stringByAppendingPathExtension:@"html"] atomically:YES encoding:controller.encoding error:&error]) {
        NSLog(@"couldn't write indexHTML: %@, %@", error.localizedDescription, error.localizedFailureReason);
    }
}

@end
