//
//  ScreenSaverStartAction.h
//  MarcoPolo
//
//  Created by David Symonds on 4/11/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithBool.h"


@interface ScreenSaverStartAction : ActionWithBool {
}

- (NSString *)descriptionOfState:(BOOL)state;
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
