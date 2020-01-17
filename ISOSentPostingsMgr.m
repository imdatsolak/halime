//
//  ISOSentPostingsMgr.m
//  Halime
//
//  Created by Imdat Solak on Sun Jan 13 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOSentPostingsMgr.h"
#import "ISOResourceMgr.h"

#define MAC_SENTIDSFILE	@"SentMessageIDs.plist"

@implementation ISOSentPostingsMgr
static id sharedInstance = nil;

+ (id)sharedInstance
{
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (id)init
{
	if (sharedInstance) {
		sentPostingIDs = nil;
		needsSaving = NO;
		[self dealloc];
		return sharedInstance;
	} else {
		NSString	*aString;
		[super init];
		
		aString = [ISOResourceMgr fullResourcePathForFileWithString:MAC_SENTIDSFILE];
		sentPostingIDs = [NSMutableArray arrayWithContentsOfFile:aString];
		if (!sentPostingIDs) {
			sentPostingIDs = [NSMutableArray array];
		}
		[sentPostingIDs retain];
		needsSaving = NO;
		sharedInstance = self;
		return self;
	}
}
	
- (BOOL)needsSaving
{
	return needsSaving;
}

- (BOOL)save
{
	NSString	*aString;
	
	aString = [ISOResourceMgr fullResourcePathForFileWithString:MAC_SENTIDSFILE];
	if ([sentPostingIDs writeToFile:aString atomically:NO]) {
		needsSaving = NO;
		return YES;
	} else {
		return NO;
	}
}

- (void)dealloc
{
	if (sentPostingIDs && [self needsSaving]) {
		[self save];
	}
	[sentPostingIDs release];
	[super dealloc];
}

- (BOOL)addSentPostingID:(NSString *)aString
{
	[sentPostingIDs addObject:aString];
	return YES;
}

- (BOOL)expireSentPostingIDs
{
	return YES;
}

- (BOOL)isPostingAReplyToMyPostings:(ISONewsPosting *)aPosting
{
	NSString	*refHeader;
	
	refHeader = [aPosting referencesHeader];
	if (refHeader) {
		int		i, count;
		BOOL	found = NO;
		NSString	*aString;
		NSScanner	*aScanner = [NSScanner scannerWithString:refHeader];
		
		while (!found && [aScanner scanUpToString:@" " intoString:&aString]) {
			i = 0;
			count = [sentPostingIDs count];
			while (i<count && !found) {
				if ([aString compare:[sentPostingIDs objectAtIndex:i]] == NSOrderedSame) {
					found = YES;
				}
				i++;
			}
		}
		return found;
	} else {
		return NO;
	}
}

@end
