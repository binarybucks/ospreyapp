//
//  SAYAppDelegate.h
//  Osprey
//
//  Created by Alexander Rust on 08.07.12.
//  Copyright (c) 2012 IBM Deutschland GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SAYAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
