//
//  NSPopUpButton_Extensions.m
//  Halime
//
//  Created by Imdat Solak on Thu Feb 14 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "NSPopUpButton_Extensions.h"


@implementation NSPopUpButton(Extensions)

- (void)selectItemWithTag:(int)tag
{
	int i, count;
	BOOL	found = NO;
	NSArray	*itemArray = [self itemArray];
	count = [itemArray count];
	i=0;
	while (i<count && !found) {
		if ([[itemArray objectAtIndex:i] tag] == tag) {
			[self selectItem:[itemArray objectAtIndex:i]];
			found = YES;
		}
		i++;
	}
}

@end
