//
//  ISOOutPostingMgr.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 26 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOOutPostingMgr.h"
#import "ISOOfflineMgr.h"
#import "ISOResourceMgr.h"
#import "ISONewsPosting.h"
#import "ISOLogger.h"
#import "ISOBeep.h"

#define K_OUTPOSTINGSFILE	@"OutgoingPostings.plist"

@implementation ISOOutPostingMgr
static ISOOutPostingMgr	*sharedOutPostingMgr = nil;

+ sharedOutPostingMgr
{
	if (!sharedOutPostingMgr) {
		sharedOutPostingMgr = [[self alloc] init];
	}
	return sharedOutPostingMgr;
}

- (void)_loadOutPostings
{
	NSString	*aString;
	NSArray		*outPostingPlist;
	
	outPostings = [[NSMutableArray array] retain];
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_OUTPOSTINGSFILE];
	outPostingPlist = [NSMutableArray arrayWithContentsOfFile:aString];
	if (outPostingPlist) {
		int	i, count;
		count = [outPostingPlist count];
		for (i=0;i<count;i++) {
			ISONewsPosting 	*aPosting = [[ISONewsPosting alloc] initFromString:[outPostingPlist objectAtIndex:i]];
			[outPostings addObject:aPosting];
			[[ISOOfflineMgr sharedOfflineMgr] addToUploads:aPosting];
			[aPosting autorelease];
		}
	}
}

- (void)_saveOutPostings
{
	NSString		*aString;
	NSMutableArray	*outPostingPlist;
	int	i, count;
	
	outPostingPlist = [NSMutableArray array];
	
	count = [outPostings count];
	for (i=0;i<count;i++) {
		NSMutableString	*postingText = [NSMutableString string];
		if ([[outPostings objectAtIndex:i] writeToString:postingText]) {
			[outPostingPlist addObject:postingText];
		}
	}
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_OUTPOSTINGSFILE];
	[outPostingPlist writeToFile:aString atomically:NO];
}


- init
{
	if (!sharedOutPostingMgr) {
		sharedOutPostingMgr = [super init];
		[self _loadOutPostings];
	} else {
		[self dealloc];
	}
	return sharedOutPostingMgr;
}

- (void)dealloc
{
	[outPostings release];
	[super dealloc];
}


- addOutPosting:(ISONewsPosting *)aPosting requester:(id)sender
{
	[outPostings addObject:aPosting];
	if (sender != [ISOOfflineMgr sharedOfflineMgr]) {
		[[ISOOfflineMgr sharedOfflineMgr] addToUploads:aPosting];
	}
	[self _saveOutPostings];
	return self;
}

- removeOutPosting:(ISONewsPosting *)aPosting requester:(id)sender
{
	[outPostings removeObject:aPosting];
	[self _saveOutPostings];
	if (sender != [ISOOfflineMgr sharedOfflineMgr]) {
		[[ISOOfflineMgr sharedOfflineMgr] removeFromUploads:aPosting];
	}
	return self;
}

- (void)outpostingsChanged:sender
{
	[self _saveOutPostings];
}

- (void)ping
{
	[ISOActiveLogger logWithDebuglevel:1 :@"Outposting Mgr created"];
}
@end
