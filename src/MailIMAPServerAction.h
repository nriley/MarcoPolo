//
//  MailIMAPServerAction.h
//  MarcoPolo
//
//  Created by David Symonds on 10/08/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithString.h"


@interface MailIMAPServerAction : ActionWithString {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
