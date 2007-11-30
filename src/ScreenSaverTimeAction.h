//
//  ScreenSaverTimeAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/16/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithLimitedOptions.h"


@interface ScreenSaverTimeAction : ActionWithLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
