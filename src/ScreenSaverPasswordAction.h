//
//  ScreenSaverPasswordAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <Cocoa/Cocoa.h>
#import "ToggleableAction.h"


@interface ScreenSaverPasswordAction : ToggleableAction {
}

- (NSString *)suggestionLeadText;
- (NSString *)descriptionOfState:(BOOL)state;
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
