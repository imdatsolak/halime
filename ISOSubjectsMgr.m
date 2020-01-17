//
//  ISOSubjectsMgr.m
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSubjectsMgr.h"
#import "ISOResourceMgr.h"
#import "ISOLogger.h"

#define K_FRIENDSFILE	@"Subjects.plist"

@implementation ISOSubjectsMgr
static ISOSubjectsMgr	*sharedSubjectMgr = nil;

+ sharedSubjectsMgr
{
	if (!sharedSubjectMgr) {
		sharedSubjectMgr = [[self alloc] init];
	}
	return sharedSubjectMgr;
}

- (void)_loadSubjects
{
	NSString	*aString;
	
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_FRIENDSFILE];
	subjects = [NSMutableArray arrayWithContentsOfFile:aString];
	if (!subjects) {
		subjects = [NSMutableArray array];
	}
	[subjects retain];
}

- (void)_saveSubjects
{
	NSString		*aString;

	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_FRIENDSFILE];
	[subjects writeToFile:aString atomically:NO];
}


- init
{
	if (!sharedSubjectMgr) {
		sharedSubjectMgr = [super init];
		[self _loadSubjects];
	} else {
		[self dealloc];
	}
	return sharedSubjectMgr;
}

- (void)dealloc
{
	[subjects release];
	[super dealloc];
}


- addSubject:(NSString *)aSubject requester:(id)sender
{
	[subjects addObject:aSubject];
	[self _saveSubjects];
	return self;
}

- removeSubjectAtIndex:(int)anIndex requester:(id)sender
{
	if (anIndex >=0 && (anIndex < [subjects count])) {
		[subjects removeObjectAtIndex:anIndex];
	}
	[self _saveSubjects];
	return self;
}

- replaceSubjectAtIndex:(int)anIndex withSubject:(NSString *)aSubject requester:(id)sender
{
	if (anIndex >=0 && (anIndex < [subjects count])) {
		[subjects replaceObjectAtIndex:anIndex withObject:aSubject];
	}
	return self;
}

- (NSString *)subjectAtIndex:(int)index
{
	if (index >=0 && (index < [subjects count])) {
		return [subjects objectAtIndex:index];
	} else {
		return nil;
	}
}

- (int)subjectsCount
{
	return [subjects count];
}
- (void)subjectsChanged:sender
{
	[self _saveSubjects];
}

- (NSArray *)subjects
{
	return subjects;
}

- (void)ping
{
	[ISOActiveLogger logWithDebuglevel:1 :@"Subjects Mgr created"];
}
@end
