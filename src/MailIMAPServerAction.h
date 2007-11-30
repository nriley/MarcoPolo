//
//  MailIMAPServerAction.h
//  MarcoPolo
//
//  Created by David Symonds on 10/08/07.
//

#import <Cocoa/Cocoa.h>
#import "StringAction.h"


@interface MailIMAPServerAction : StringAction {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
