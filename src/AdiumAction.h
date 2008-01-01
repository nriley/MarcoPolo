//
//  AdiumAction.h
//  MarcoPolo
//
//  Created by David Symonds on 28/12/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithTwoLimitedOptions.h"


#define kAllAdiumAccounts	@"*"

@interface AdiumAction : ActionWithTwoLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)leadText;
- (NSArray *)firstSuggestions;		// accounts
- (NSArray *)secondSuggestions;		// statuses

@end
