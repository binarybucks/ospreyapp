//
//  INKeychainAccess.h
//  ExampleApp
//
//  Created by Indragie Karunaratne on 10-11-24.
//  Copyright 2010 Indragie Karunaratne. All rights reserved.
//
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface INKeychainAccess : NSObject {
}
#if TARGET_OS_IPHONE
#else
/** 
 Returns the SecKeychainItemRef for the account with the specified parameters (Mac only)
 @param account the account name
 @param name the service name
 */
+ (SecKeychainItemRef)itemRefForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error;
#endif
/**
 Returns the password for the account with the specified parameters
 @param account the account name
 @param name the service name
 */
+ (NSString*)passwordForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error;
/**
 Sets a new password for an existing keychain item for the specified account
 @param password the new password
 @param account the account name
 @param name the service name
 */
+ (BOOL)setPassword:(NSString*)password forAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error;
/**
 Creates a new keychain item for the account with the specified parameters
 @param account the account name
 @param password the account password
 @param name the service name
 */
+ (BOOL)addKeychainItemForAccount:(NSString*)account withPassword:(NSString*)password serviceName:(NSString*)name error:(NSError**)error;
/**
 Removes the keychain item for the account with the specified parameters
 @param account the account name
 @param name the service name
*/
+ (BOOL)removeKeychainItemForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error;
@end
