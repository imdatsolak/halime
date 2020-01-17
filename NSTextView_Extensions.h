//
//  NSTextView_Extensions.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 12 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTextView(Extensions)

- (IBAction) rot13: (id)sender;
- (void) displayUsenetAttributes;
- (void) colorizeRange: (NSRange)aRange;

@end
