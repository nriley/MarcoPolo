//
//  SleepTimeAction.h
//  MarcoPolo
//
//  Created by James Newton on 23/11/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithTwoLimitedOptions.h"


@interface SleepTimeAction : ActionWithTwoLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)leadText;
- (NSArray *)firstSuggestions;		// thing to change sleep time (computer/disk/display)
- (NSArray *)secondSuggestions;		// time to set

@end
