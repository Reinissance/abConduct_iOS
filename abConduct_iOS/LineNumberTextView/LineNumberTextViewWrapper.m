//
//  LineNumberTextViewWrapper.m
//  TextKit_LineNumbers
//
//  Created by Mark Alldritt on 2013-10-11.
//  Copyright (c) 2013 Late Night Software Ltd. All rights reserved.
//

#import "LineNumberTextViewWrapper.h"

//
//  This class is here so that we can use a storyboard.  This is required because we must use the UITextView's
//  -[initWithFrame:textContainer:] initializer in order to substitute our own layout manager.  This cannot be done
//  using UITextView's -[initWithCoder:] initializer which is the one used whe views are created from a storyboard.
//
//  This class also

@implementation LineNumberTextViewWrapper

- (id) initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.textView = [[LineNumberTextView alloc] initWithFrame:self.bounds];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.textView];
    }
    return self;
}

- (UIFont *)lineNumberFont {
    return self.textView.lineNumberFont;
}

- (void)setLineNumberFont:(UIFont *)lineNumberFont {
    self.textView.lineNumberFont = lineNumberFont;
}

- (UIColor *)lineNumberBackgroundColor {
    return self.textView.lineNumberBackgroundColor;
}

- (void)setLineNumberBackgroundColor:(UIColor *)lineNumberBackgroundColor {
    self.textView.lineNumberBackgroundColor = lineNumberBackgroundColor;
}

- (UIColor *)lineNumberBorderColor {
    return self.textView.lineNumberBorderColor;
}

- (void)setLineNumberBorderColor:(UIColor *)lineNumberBorderColor {
    self.textView.lineNumberBorderColor = lineNumberBorderColor;
}

- (UIColor *)lineNumberTextColor {
    return self.textView.lineNumberTextColor;
}

- (void)setLineNumberTextColor:(UIColor *)lineNumberTextColor {
    self.textView.lineNumberTextColor = lineNumberTextColor;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray<UIKeyCommand *>*)keyCommands {
    return @[
             [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyS:)],
             [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyR:)],
             [UIKeyCommand keyCommandWithInput:@"p" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyP:)],
             [UIKeyCommand keyCommandWithInput:@"t" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyT:)],
             [UIKeyCommand keyCommandWithInput:@"e" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyE:)],
             [UIKeyCommand keyCommandWithInput:@"o" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyO:)],
             [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyD:)],
             [UIKeyCommand keyCommandWithInput:@"n" modifierFlags:UIKeyModifierCommand action:@selector(commandPressedKeyN:)]
             ];
}

- (void) commandPressedKeyS: (id) sender {
    [self.delegate storeText];
}

- (void) commandPressedKeyR: (id) sender {
    [self.delegate renderText];
}

- (void) commandPressedKeyP: (id) sender {
    [self.delegate playBack];
}

- (void) commandPressedKeyT: (id) sender {
    [self.delegate transpose];
}

- (void) commandPressedKeyE: (id) sender {
    [self.delegate exportDocument];
}

- (void) commandPressedKeyO: (id) sender {
    [self.delegate loadDocument];
}

- (void) commandPressedKeyD: (id) sender {
    [self.delegate displayDocument];
}

- (void) commandPressedKeyN: (id) sender {
    [self.delegate newDocument];
}

@end
