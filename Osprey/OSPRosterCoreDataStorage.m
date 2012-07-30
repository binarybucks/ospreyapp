//
//  OSPRosterCoreDataStorage.m
//  Osprey
//
//  Created by Alexander Rust on 20.07.12.
//  Copyright (c) 2012 IBM Deutschland GmbH. All rights reserved.
//

#import "OSPRosterCoreDataStorage.h"

@implementation OSPRosterCoreDataStorage

- (void)mainThreadManagedObjectContextDidMergeChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rosterStorageMainThreadManagedObjectContextDidMergeChanges" object:nil];
}

@end
