//
//  ScreenSaverStartAction.h
//  MarcoPolo
//
//  Created by David Symonds on 4/11/07.
//

#import <Cocoa/Cocoa.h>
#import "ToggleableAction.h"


@interface ScreenSaverStartAction : ToggleableAction {
}

- (NSString *)descriptionOfState:(BOOL)state;
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
