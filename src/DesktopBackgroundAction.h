//
//  DesktopBackgroundAction.h
//  MarcoPolo
//
//  Created by David Symonds on 12/11/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithFile.h"


@interface DesktopBackgroundAction : ActionWithFile {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
