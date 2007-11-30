//
//  VPNAction.h
//  MarcoPolo
//
//  Created by Mark Wallis on 18/07/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithLimitedOptions.h"


@interface VPNAction : ActionWithLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
