//
//  ISOBeep.h
//  Halime
//
//  Created by iso on Thu Aug 16 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ISOBeep : NSObject 
{

}
+ beep:(NSString *)beepReason withDescription:(NSString *)descString andHelp:(NSString *)helpIndex;
+ beep:(NSString *)beepReason withDescription:(NSString *)descString;
+ beep:(NSString *)beepReason;
+ whyTheBeep:sender;
@end
