//
//  INKeychainAccess.m
//  ExampleApp
//
//  Created by Indragie Karunaratne on 10-11-24.
//  Copyright 2010 Indragie Karunaratne. All rights reserved.
//
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#import "INKeychainAccess.h"

static NSString* const kKeychainAccessErrorDomain = @"INKeychainAccessErrorDomain";

@interface INKeychainAccess ()
#if TARGET_OS_IPHONE
#else
+ (NSError*)_errorWithStatus:(OSStatus)status;
#endif
+ (NSError*)_errorWithMessage:(NSString*)message;
@end


@implementation INKeychainAccess

+ (NSError*)_errorWithMessage:(NSString*)message
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil];
    return [NSError errorWithDomain:kKeychainAccessErrorDomain code:0 userInfo:userInfo];
}

#if TARGET_OS_IPHONE

+ (NSString*)passwordForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return nil; 
    }
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:name, kSecAttrService, account, kSecAttrAccount, kSecClassGenericPassword, kSecClass, kCFBooleanTrue, kSecReturnData, nil];
    CFDataRef passwordData = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef*)&passwordData);
    if (status) {
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Failed to retrieve password for account \"%@\" for service \"%@\"", account, name]];
        }
        return nil;
    }
    NSString *password = [[NSString alloc] initWithData:(NSData*)passwordData encoding:NSUTF8StringEncoding];
    CFRelease(passwordData);
    return [password autorelease];
}

+ (BOOL)setPassword:(NSString*)password forAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name || !password) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO;
    }
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:name, kSecAttrService, account, kSecAttrAccount, kSecClassGenericPassword, kSecClass, nil];
    NSDictionary *updated = [NSDictionary dictionaryWithObjectsAndKeys:[password dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil];
    OSStatus status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)updated);
    if (status) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Failed to set password for account \"%@\" for service \"%@\"", account, name]];
        }
        return NO; 
    }
    return YES;
}

+ (BOOL)addKeychainItemForAccount:(NSString*)account withPassword:(NSString*)password serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name || !password) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO;
    }
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:name, kSecAttrService, account, kSecAttrAccount, kSecClassGenericPassword, kSecClass,  [password dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil];
    OSStatus status = SecItemAdd((CFDictionaryRef)query, NULL);
    if (status) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Failed to create keychain item for account \"%@\" for service \"%@\"", account, name]];
        }
        return NO; 
    }
    return YES;
}

+ (BOOL)removeKeychainItemForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO;
    }
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:name, kSecAttrService, account, kSecAttrAccount, kSecClassGenericPassword, kSecClass, nil];
    OSStatus status = SecItemDelete((CFDictionaryRef)query);
    if (status) {
        if (error) {
             *error = [self _errorWithMessage:[NSString stringWithFormat:@"Failed to remove keychain item for account \"%@\" for service \"%@\"", account, name]];
        }
        return NO;
    }
    return YES;
}

#else
+ (NSError*)_errorWithStatus:(OSStatus)status
{
    NSString *message = [(NSString*)SecCopyErrorMessageString(status, NULL) autorelease];
    return [self _errorWithMessage:message];
}

+ (SecKeychainItemRef)itemRefForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return nil; 
    }
    SecKeychainItemRef itemRef;
    OSStatus status = SecKeychainFindGenericPassword(NULL, (UInt32)[name length], [name UTF8String], (UInt32)[account length], [account UTF8String], NULL, NULL, &itemRef);
    if (status) {
        if (error) { *error = [self _errorWithStatus:status]; }
        return NULL;
    }
    return itemRef;
}

+ (BOOL)removeKeychainItemForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO;
    }
    SecKeychainItemRef itemRef;
    OSStatus status = SecKeychainFindGenericPassword(NULL, (UInt32)[name length], [name UTF8String], (UInt32)[account length], [account UTF8String], NULL, NULL, &itemRef);
    if (status && error) {
        *error = [self _errorWithStatus:status];
        return NO;
    }
    status = SecKeychainItemDelete(itemRef);
    if (status) {
        if (error) { *error = [self _errorWithStatus:status]; }
        return NO;
    }
    return YES;
}

+ (NSString*)passwordForAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return nil; 
    }
    void *passwordData = NULL;
    UInt32 passwordLength = 0;
    OSStatus status = SecKeychainFindGenericPassword(NULL, (UInt32)[name length], [name UTF8String], (UInt32)[account length], [account UTF8String], &passwordLength, &passwordData, NULL);
    if (status) {
        if (error) { *error = [self _errorWithStatus:status]; }
        return nil;
    }
    if (passwordData == NULL || !passwordLength) {
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"No password data for account \"%@\" for service \"%@\"", account, name]];
        }
        return nil; 
    }
    NSString *password = [[NSString alloc] initWithBytes:passwordData length:(NSUInteger)passwordLength encoding:NSUTF8StringEncoding];
    SecKeychainItemFreeContent(NULL, passwordData);
    return [password autorelease];
}

+ (BOOL)addKeychainItemForAccount:(NSString*)account withPassword:(NSString*)password serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !password || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO; 
    }
    OSStatus status = SecKeychainAddGenericPassword(NULL, (UInt32)[name length], [name UTF8String], (UInt32)[account length], [account UTF8String], (UInt32)[password length], [password UTF8String], NULL);
    if (status) {
        if (error) { *error = [self _errorWithStatus:status]; }
        return NO;
    }
    return YES;
}

+ (BOOL)setPassword:(NSString*)password forAccount:(NSString*)account serviceName:(NSString*)name error:(NSError**)error
{
    if (!account || !password || !name) { 
        if (error) {
            *error = [self _errorWithMessage:[NSString stringWithFormat:@"Invalid arguments to method %@", NSStringFromSelector(_cmd)]];
        }
        return NO; 
    }
    SecKeychainItemRef itemRef = [self itemRefForAccount:account serviceName:name error:error];
    if (itemRef == NULL) { return NO; }
    OSStatus status = SecKeychainItemModifyAttributesAndData(itemRef, NULL, (UInt32)[password length], [password UTF8String]);
    if (status) {
        if (error) { *error = [self _errorWithStatus:status]; }
        return NO;
    }
    return YES;
}
#endif
@end
