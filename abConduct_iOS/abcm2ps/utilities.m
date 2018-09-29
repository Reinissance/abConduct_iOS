//
//  utilities.m
//
// found here: https://gist.github.com/mopsled/4616532, modified


#include "utilities.h"
#import <Foundation/Foundation.h>


FILE *iosfopen(const char *filename, const char *mode) {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *webFolder = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
    NSString *fileString = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
    NSString *path = [webFolder stringByAppendingPathComponent:fileString];
    const char *filePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
    
    return fopen(filePath, mode);
}
