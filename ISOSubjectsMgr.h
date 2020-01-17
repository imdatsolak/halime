//
//  ISOSubjectsMgr.h
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISOSubjectsMgr : NSObject
{
	NSMutableArray	*subjects;
}
+ sharedSubjectsMgr;
- (void)_loadSubjects;
- (void)_saveSubjects;
- init;
- (void)dealloc;
- addSubject:(NSString *)aSubject requester:(id)sender;
- removeSubjectAtIndex:(int)anIndex requester:(id)sender;
- replaceSubjectAtIndex:(int)anIndex withSubject:(NSString *)aSubject requester:(id)sender;
- (NSString *)subjectAtIndex:(int)index;
- (int)subjectsCount;
- (void)subjectsChanged:sender;
- (NSArray *)subjects;
- (void)ping;
@end
