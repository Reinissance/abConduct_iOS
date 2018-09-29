//
//  abcRenderer.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 29.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

@interface abcRenderer : NSArray

@property NSMutableArray *svgFilePaths;
- (instancetype) initWithAbcFile: (NSString*) abcFile;

@end
