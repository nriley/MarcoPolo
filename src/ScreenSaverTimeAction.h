//
//  ScreenSaverTimeAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/16/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericAction.h"


@interface ScreenSaverTimeAction : GenericAction {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
