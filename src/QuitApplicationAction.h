//
//  QuitApplicationAction.h
//  MarcoPolo
//
//  Created by David Symonds on 15/10/07.
//

#import <Cocoa/Cocoa.h>
#import "StringAction.h"


@interface QuitApplicationAction : StringAction {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
