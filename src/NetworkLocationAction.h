//
//  NetworkLocationAction.h
//  MarcoPolo
//
//  Created by David Symonds on 4/07/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithLimitedOptions.h"


@interface NetworkLocationAction : ActionWithLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
