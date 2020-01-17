//
//  ISOGraphicalTVMgr.h
//  Halime
//
//  Created by Imdat Solak on Fri Feb 01 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"


@interface ISOGraphicalTVMgr : NSObject
{
	id	graphicalTV;
	id	drawer;
	id	target;
	SEL	action;
	SEL	doubleAction;
	id	owner;
	ISONewsPosting	*selectedPosting;
	id	imageSizePopup;
	id	detailedTooltipSwitch;
}

- init;
- (void)dealloc;
- (void)toggleDrawer;
- (void)setThread:(NSArray *)aThread ofOwner:(id)anObject;
- (void)redisplayPosting:(ISONewsPosting *)aPosting;
- (void)setTarget:(id)anObject;
- (void)setAction:(SEL)anAction;
- (void)setDoubleAction:(SEL)anAction;
- (BOOL)isShowingGTV;
- (id)owner;
- (void)setOwner:(id)anObject;
- (ISONewsPosting *)selectedPosting;
- (void)changeImageSizeTo:(int)aSize;
- (void)changeImageSize:(id)sender;
- (void)toggleDetailedTooltip:(id)sender;
/* *************** Graphical TV Target Methods ************** */
- (void)graphicalTV:(id)graphicalTV itemSelected:(ISONewsPosting *)aPosting;
- (void)graphicalTV:(id)graphicalTV itemDoubleClicked:(ISONewsPosting *)aPosting;
- (void)graphicalTV:(id)graphicalTV itemRightClicked:(ISONewsPosting *)aPosting;
@end

@interface NSObject(ISOGraphicalTVMgrOwner)
- (void)gtv:(id)sender imageSizeChangedTo:(int)aSize;
@end