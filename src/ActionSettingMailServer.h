//
//  ActionSettingMailServer.h
//  MarcoPolo
//
//  Created by David Symonds on 11/12/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithTwoLimitedOptions.h"
#import "FlexControls.h"


#define kAllMailAccounts	@"*"

@interface ActionSettingMailServer : ActionWithTwoLimitedOptions {
}

// Need to be implemented by descendant classes
- (NSString *)leadText;
- (NSArray *)firstSuggestions;	// optional; will default to all Mail's accounts
- (NSArray *)secondSuggestions;	// should return array of dictionaries for possible servers

@end
