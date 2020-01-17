//
//  ISOReadPostingTextView.m
//  Halime
//
//  Created by Imdat Solak on Wed Apr 03 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOReadPostingTextView.h"
#import "ISOReaderWindow.h"

@implementation ISOReadPostingTextView

- (void)keyDown:(NSEvent *)theEvent
{
	if (![((ISOReaderWindow *)[self window]) tryKeyDown:theEvent]) {
		[super keyDown:theEvent];
	}
}


@end
