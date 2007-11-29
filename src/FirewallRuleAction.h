//
//  FirewallRuleAction.h
//  MarcoPolo
//
//  Created by Mark Wallis on 17/07/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericAction.h"


@interface FirewallRuleAction : GenericAction {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
