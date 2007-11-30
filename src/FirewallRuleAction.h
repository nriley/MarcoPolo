//
//  FirewallRuleAction.h
//  MarcoPolo
//
//  Created by Mark Wallis on 17/07/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithLimitedOptions.h"


@interface FirewallRuleAction : ActionWithLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
