//
//  ISOPostingCanceler.h
//  Halime
//
//  Created by Imdat Solak on Thu Mar 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"
#import "ISONewsGroup.h"

@interface ISOPostingCanceler : NSObject 
{
	id	cancelPanel;
	id	messageIDField;
	id	originalSubjectField;
	id	originalNewsgroupsField;
	id	originalSenderField;
	id	dateSentField;
	id	cancelReasonPopup;
	
	ISONewsPosting	*postingToCancel;
	ISONewsGroup	*activeGroup;
}

- (BOOL)canCancelPosting:(ISONewsPosting *)aPosting;
- (void)runSheetForWindow:(id)aWindow withPosting:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup;

- (void)cancelPosting:sender;
- (void)abort:sender;

@end
